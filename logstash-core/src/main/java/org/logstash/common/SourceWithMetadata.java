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


package org.logstash.common;

import org.logstash.config.ir.HashableWithSource;

import java.util.Arrays;
import java.util.Collection;
import java.util.List;
import java.util.Objects;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

public class SourceWithMetadata implements HashableWithSource {
    // Either 'file' or something else
    private final String protocol;
    // A Unique identifier for the source within the given protocol
    // For a file, this is its path
    private final String id;
    private final Integer line;
    private final Integer column;
    private final String text;
    private int linesCount;
    private final String metadata;

    public String getProtocol() {
        return this.protocol;
    }

    public String getId() {
        return id;
    }

    public Integer getLine() {
        return line;
    }

    public Integer getColumn() {
        return column;
    }

    public String getText() {
        return text;
    }

    public String getMetadata() { return metadata; }

    private static final Pattern emptyString = Pattern.compile("^\\s*$");

    public SourceWithMetadata(String protocol, String id, Integer line, Integer column, String text, String metadata) throws IncompleteSourceWithMetadataException {
        this.protocol = protocol;
        this.id = id;
        this.line = line;
        this.column = column;
        this.text = text;
        this.metadata = metadata;

        List<Object> badAttributes = this.attributes().stream().filter(a -> {
            if (a == null) return true;
            if (a instanceof String) {
                return emptyString.matcher((String) a).matches();
            }
            return false;
        }).collect(Collectors.toList());

        if (!(this.getText() instanceof String)) {
          badAttributes.add(this.getText());
        }

        if (!badAttributes.isEmpty()) {
            String message = "Missing attributes in SourceWithMetadata: (" + badAttributes + ") " + this.toString();
            throw new IncompleteSourceWithMetadataException(message);
        }

        this.linesCount = text.split("\\n").length;
    }

    public SourceWithMetadata(String protocol, String id, String text) throws IncompleteSourceWithMetadataException {
        this(protocol, id, 0, 0, text, "");
    }

    public SourceWithMetadata(String protocol, String id, String text, String metadata) throws IncompleteSourceWithMetadataException {
        this(protocol, id, 0, 0, text, metadata);
    }

    public SourceWithMetadata(String protocol, String id, Integer line, Integer column, String text) throws IncompleteSourceWithMetadataException {
        this(protocol, id, line, column, text, "");
    }

    public int hashCode() {
        return Objects.hash(hashableAttributes().toArray());
    }

    public String toString() {
        return "[" + protocol + "]" + id + ":" + line + ":" + column + ":```\n" + text + "\n```";
    }

    @Override
    public String hashSource() {
        return hashableAttributes().stream().map(Object::toString).collect(Collectors.joining("|"));
    }

    // Fields checked for being not null and non empty String
    private Collection<Object> attributes() {
        return Arrays.asList(this.getId(), this.getProtocol(), this.getLine(), this.getColumn());
    }

    // Fields used in the hashSource and hashCode methods to ensure uniqueness
    private Collection<Object> hashableAttributes() {
        return Arrays.asList(this.getId(), this.getProtocol(), this.getLine(), this.getColumn(), this.getText());
    }

    public int getLinesCount() {
        return linesCount;
    }

    public boolean equalsWithoutText(SourceWithMetadata other) {
        return getProtocol().equals(other.getProtocol())
                && getId().equals(other.getId())
                && getLine().equals(other.getLine())
                && getColumn().equals(other.getColumn());
    }
}
