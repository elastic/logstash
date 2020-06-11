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

import org.jruby.*;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.junit.Test;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

import static org.junit.Assert.*;

public class PipelineConfigTest extends RubyEnvTestCase {

    public static final String PIPELINE_ID = "main";
    private RubyClass source;
    private RubySymbol pipelineIdSym;
    private String configMerged;
    private SourceWithMetadata[] unorderedConfigParts;

    private final static RubyObject SETTINGS = (RubyObject) RubyUtil.RUBY.evalScriptlet(
            "require 'logstash/environment'\n" + // this is needed to register "pipeline.system" setting
            "require 'logstash/settings'\n" +
            "LogStash::SETTINGS");
    private PipelineConfig sut;
    private SourceWithMetadata[] orderedConfigParts;
    public static final String PIPELINE_CONFIG_PART_2 =
            "output {\n" +
            "  stdout\n" +
            "}";
    public static final String PIPELINE_CONFIG_PART_1 =
            "input {\n" +
            "  generator1\n" +
            "}";

    @Before
    public void setUp() throws IncompleteSourceWithMetadataException {

        source = RubyUtil.RUBY.getClass("LogStash::Config::Source::Local");
        pipelineIdSym = RubySymbol.newSymbol(RubyUtil.RUBY, PIPELINE_ID);

        orderedConfigParts = new SourceWithMetadata[]{
                new SourceWithMetadata("file", "/tmp/1", 0, 0, "input { generator1 }"),
                new SourceWithMetadata("file", "/tmp/2", 0, 0, "input { generator2 }"),
                new SourceWithMetadata("file", "/tmp/3", 0, 0, "input { generator3 }"),
                new SourceWithMetadata("file", "/tmp/4", 0, 0, "input { generator4 }"),
                new SourceWithMetadata("file", "/tmp/5", 0, 0, "input { generator5 }"),
                new SourceWithMetadata("file", "/tmp/6", 0, 0, "input { generator6 }"),
                new SourceWithMetadata("string", "config_string", 0, 0, "input { generator1 }"),
        };

        configMerged = Arrays.stream(orderedConfigParts).map(SourceWithMetadata::getText).collect(Collectors.joining("\n"));

        List<SourceWithMetadata> unorderedList = Arrays.asList(orderedConfigParts);
        Collections.shuffle(unorderedList);
        unorderedConfigParts = unorderedList.toArray(new SourceWithMetadata[0]);

        sut = new PipelineConfig(source, pipelineIdSym, toRubyArray(unorderedConfigParts), SETTINGS);
    }

    @Test
    public void testReturnsTheSource() {
        assertEquals("returns the source", source, sut.getSource());
        assertEquals("returns the pipeline id", PIPELINE_ID, sut.getPipelineId());
        assertNotNull("returns the config_hash", sut.configHash());
        assertEquals("returns the merged `ConfigPart#config_string`", configMerged, sut.configString());
        assertTrue("records when the config was read", sut.getReadAt().isBefore(LocalDateTime.now()));
    }

    @SuppressWarnings("rawtypes")
    private static RubyArray toRubyArray(SourceWithMetadata[] arr) {
        List<IRubyObject> wrappedContent = Arrays.stream(arr).map(RubyUtil::toRubyObject).collect(Collectors.toList());
        return RubyArray.newArray(RubyUtil.RUBY, wrappedContent);
    }

    @Test
    public void testObjectEqualityOnConfigHashAndPipelineId() {
        PipelineConfig anotherExactPipeline = new PipelineConfig(source, pipelineIdSym, toRubyArray(orderedConfigParts), SETTINGS);
        assertEquals(anotherExactPipeline, sut);

        final RubyObject CLONED_SETTINGS = (RubyObject)SETTINGS.callMethod("clone");
        PipelineConfig anotherExactPipelineWithClonedSettings = new PipelineConfig(source, pipelineIdSym, toRubyArray(orderedConfigParts), CLONED_SETTINGS);
        assertEquals(anotherExactPipelineWithClonedSettings, sut);

        PipelineConfig notMatchingPipeline = new PipelineConfig(source, pipelineIdSym, RubyArray.newEmptyArray(RubyUtil.RUBY), SETTINGS);
        assertNotEquals(notMatchingPipeline, sut);

        PipelineConfig notSamePipelineId = new PipelineConfig(source, RubySymbol.newSymbol(RubyUtil.RUBY, "another_pipeline"), toRubyArray(unorderedConfigParts), SETTINGS);
        assertNotEquals(notSamePipelineId, sut);
    }

    @Test
    public void testIsSystemWhenPipelineIsNotSystemPipeline() {
        assertFalse("returns false if the pipeline is not a system pipeline", sut.isSystem());
    }

    @Test
    public void testIsSystemWhenPipelineIsSystemPipeline() {
        RubyObject mockedSettings = mockSettings(Collections.singletonMap("pipeline.system", true));
        sut = new PipelineConfig(source, pipelineIdSym, toRubyArray(unorderedConfigParts), mockedSettings);

        assertTrue("returns true if the pipeline is a system pipeline", sut.isSystem());
    }

    public RubyObject mockSettings(Map<String, Object> settingsValues) {
        IRubyObject settings = SETTINGS.callMethod("clone");
        settingsValues.forEach((k, v) -> {
            RubyString rk = RubyString.newString(RubyUtil.RUBY, k);
            IRubyObject rv = RubyUtil.toRubyObject(v);
            settings.callMethod(RubyUtil.RUBY.getCurrentContext(), "set", new IRubyObject[]{rk, rv});
        });
        return (RubyObject) settings;
    }

    @Test
    public void testSourceAndLineRemapping_pipelineDefinedInSingleFileOneLine() throws IncompleteSourceWithMetadataException {
        String oneLinerPipeline = "input { generator1 }";
        final SourceWithMetadata swm = new SourceWithMetadata("file", "/tmp/1", 0, 0, oneLinerPipeline);
        sut = new PipelineConfig(source, pipelineIdSym, toRubyArray(new SourceWithMetadata[]{swm}), SETTINGS);

        assertEquals("return the same line of the queried", 1, (int) sut.lookupSource(1, 0).getLine());
    }

    @Test
    public void testSourceAndLineRemapping_pipelineDefinedInSingleFileMultiLine() throws IncompleteSourceWithMetadataException {
        final SourceWithMetadata swm = new SourceWithMetadata("file", "/tmp/1", 0, 0, PIPELINE_CONFIG_PART_1);
        sut = new PipelineConfig(source, pipelineIdSym, toRubyArray(new SourceWithMetadata[]{swm}), SETTINGS);

        assertEquals("return the same line of the queried L1", 1, (int) sut.lookupSource(1, 0).getLine());
        assertEquals("return the same line of the queried L2", 2, (int) sut.lookupSource(2, 0).getLine());
    }

    @Test(expected = IllegalArgumentException.class)
    public void testSourceAndLineRemapping_pipelineDefinedInSingleFileMultiLine_dontmatch() throws IncompleteSourceWithMetadataException {
        final SourceWithMetadata swm = new SourceWithMetadata("file", "/tmp/1", 0, 0, PIPELINE_CONFIG_PART_1);
        sut = new PipelineConfig(source, pipelineIdSym, toRubyArray(new SourceWithMetadata[]{swm}), SETTINGS);

        sut.lookupSource(100, -1);
    }

    @Test
    public void testSourceAndLineRemapping_pipelineDefinedMInMultipleFiles() throws IncompleteSourceWithMetadataException {
        final SourceWithMetadata[] parts = {
                new SourceWithMetadata("file", "/tmp/input", 0, 0, PIPELINE_CONFIG_PART_1),
                new SourceWithMetadata("file", "/tmp/output", 0, 0, PIPELINE_CONFIG_PART_2)
        };
        sut = new PipelineConfig(source, pipelineIdSym, toRubyArray(parts), SETTINGS);

        assertEquals("return the line of first segment", 2, (int) sut.lookupSource(2, 0).getLine());
        assertEquals("return the id of first segment", "/tmp/input", sut.lookupSource(2, 0).getId());
        assertEquals("return the line of second segment", 1, (int) sut.lookupSource(4, 0).getLine());
        assertEquals("return the id of second segment", "/tmp/output", sut.lookupSource(4, 0).getId());
    }

    @Test(expected = IllegalArgumentException.class)
    public void testSourceAndLineRemapping_pipelineDefinedMInMultipleFiles_dontmatch() throws IncompleteSourceWithMetadataException {
        final SourceWithMetadata[] parts = {
                new SourceWithMetadata("file", "/tmp/input", 0, 0, PIPELINE_CONFIG_PART_1),
                new SourceWithMetadata("file", "/tmp/output", 0, 0, PIPELINE_CONFIG_PART_2)
        };
        sut = new PipelineConfig(source, pipelineIdSym, toRubyArray(parts), SETTINGS);

        sut.lookupSource(100, 0);
    }

    @Test
    public void testSourceAndLineRemapping_pipelineDefinedMInMultipleFiles_withEmptyLinesInTheMiddle() throws IncompleteSourceWithMetadataException {
        final SourceWithMetadata[] parts = {
                new SourceWithMetadata("file", "/tmp/input", 0, 0, PIPELINE_CONFIG_PART_1 + "\n"),
                new SourceWithMetadata("file", "/tmp/output", 0, 0, PIPELINE_CONFIG_PART_2)
        };
        sut = new PipelineConfig(source, pipelineIdSym, toRubyArray(parts), SETTINGS);

        assertEquals("shouldn't slide the line mapping of subsequent", 1, (int) sut.lookupSource(4, 0).getLine());
        assertEquals("shouldn't slide the id mapping of subsequent", "/tmp/output", sut.lookupSource(4, 0).getId());
    }
}
