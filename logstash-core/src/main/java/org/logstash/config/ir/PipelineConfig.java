/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.logstash.config.ir;

import org.apache.commons.codec.digest.DigestUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.*;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static org.logstash.RubyUtil.RUBY;

public final class PipelineConfig {

    private static class LineToSource {
        private final int startLine;
        private final int endLine;
        private final SourceWithMetadata source;

        LineToSource(int startLine, int endLine, SourceWithMetadata source) {
            this.startLine = startLine;
            this.endLine = endLine;
            this.source = source;
        }

        boolean includeLine(int lineNumber) {
            return startLine <= lineNumber && lineNumber <= endLine;
        }
    }

    private static final Logger logger = LogManager.getLogger(PipelineConfig.class);

    private RubyClass source;
    private String pipelineId;
    private List<SourceWithMetadata> confParts;
    private RubyObject settings;
    private LocalDateTime readAt;
    private String configHash;
    private volatile String configString;
    private volatile String metadata;
    private List<LineToSource> sourceRefs;

    private static final String NEWLINE = "\n";

    @SuppressWarnings({"rawtypes", "unchecked"})
    public PipelineConfig(RubyClass source, RubySymbol pipelineId, RubyObject uncastedConfigParts, RubyObject logstashSettings) {
        IRubyObject uncasted = uncastedConfigParts.checkArrayType();
        final RubyArray configParts = !uncasted.isNil() ?
                (RubyArray) uncasted :
                RubyArray.newArray(RUBY, uncastedConfigParts);

        this.source = source;
        this.pipelineId = pipelineId.toString();
        SourceWithMetadata[] castedConfigParts = (SourceWithMetadata[]) configParts.toJava(SourceWithMetadata[].class);
        List<SourceWithMetadata> confParts = Arrays.asList(castedConfigParts);
        confParts.sort(Comparator.comparing(SourceWithMetadata::getProtocol)
                .thenComparing(SourceWithMetadata::getId));
        this.confParts = confParts;
        this.settings = logstashSettings;
        this.readAt = LocalDateTime.now();
    }

    public RubyClass getSource() {
        return source;
    }

    public String getPipelineId() {
        return pipelineId;
    }

    public List<SourceWithMetadata> getConfigParts() {
        return confParts;
    }

    public LocalDateTime getReadAt() {
        return readAt;
    }

    public RubyObject getSettings() {
        return settings;
    }

    public String configHash() {
        if (configHash == null) {
            configHash = DigestUtils.sha1Hex(configString() + metadataString());
        }
        return configHash;
    }

    public String configString() {
        if (this.configString == null) {
            synchronized(this) {
                if (this.configString == null) {
                    final StringBuilder compositeConfig = new StringBuilder();
                    for (SourceWithMetadata confPart : confParts) {
                        // If our composite config ends without a trailing newline,
                        // append one before appending the next config part
                        if (compositeConfig.lastIndexOf(NEWLINE) < compositeConfig.length() - 1 ) {
                            compositeConfig.append(NEWLINE);
                        }
                        compositeConfig.append(confPart.getText());
                    }
                    this.configString = compositeConfig.toString();
                }
            }
        }
        return this.configString;
    }

    public String metadataString() {
        if (this.metadata == null) {
            synchronized(this) {
                if (this.metadata == null) {
                    this.metadata =  confParts.stream().map(SourceWithMetadata::getMetadata).collect(Collectors.joining());
                }
            }
        }
        return this.metadata;
    }

    public boolean isSystem() {
        return this.settings.callMethod(RUBY.getCurrentContext(), "get_value",
                                        RubyString.newString(RUBY, "pipeline.system"))
                .isTrue();
    }

    @Override
    public boolean equals(Object other) {
        if (!(other instanceof PipelineConfig)) {
            return false;
        }
        PipelineConfig cother = (PipelineConfig) other;
        return configHash().equals(cother.configHash()) &&
                this.pipelineId.equals(cother.pipelineId) &&
                this.settings.equals(cother.settings);
    }

    @Override
    public int hashCode() {
        return this.configHash().hashCode();
    }

    public void displayDebugInformation() {
        logger.debug("-------- Logstash Config ---------");
        logger.debug("Config from source, source: {}, pipeline_id:: {}", source, pipelineId);

        for (SourceWithMetadata configPart : this.confParts) {
            logger.debug("Config string, protocol: {}, id: {}", configPart.getProtocol(), configPart.getId());
            logger.debug("\n\n{}", configPart.getText());
        }
        logger.debug("Merged config");
        logger.debug("\n\n{}", this.configString());
    }

    public SourceWithMetadata lookupSource(int globalLineNumber, int sourceColumn)
            throws IncompleteSourceWithMetadataException {
        LineToSource lts = this.sourceReferences().stream()
                .filter(lts1 -> lts1.includeLine(globalLineNumber))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("can't find the config segment related to line " + globalLineNumber));
        return new SourceWithMetadata(lts.source.getProtocol(), lts.source.getId(),
                globalLineNumber + 1 - lts.startLine, sourceColumn, lts.source.getText());
    }

    private List<LineToSource> sourceReferences() {
        if (this.sourceRefs == null) {
            int offset = 0;
            List<LineToSource> sourceRefs = new ArrayList<>();

            for (SourceWithMetadata configPart : confParts) {
                //line numbers starts from 1 in text files
                int startLine = configPart.getLine() + offset + 1;
                int endLine = configPart.getLinesCount() + offset;
                LineToSource sourceSegment = new LineToSource(startLine, endLine, configPart);
                sourceRefs.add(sourceSegment);
                offset += configPart.getLinesCount();
            }
            this.sourceRefs = Collections.unmodifiableList(sourceRefs);
        }
        return this.sourceRefs;
    }

}
