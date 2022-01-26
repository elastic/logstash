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

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;

import org.junit.Test;
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.PluginVertex;
import org.logstash.plugins.ConfigVariableExpander;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.*;

public class ConfigCompilerTest extends RubyEnvTestCase {

    @Test
    public void testConfigToPipelineIR() throws Exception {
        SourceWithMetadata swm = new SourceWithMetadata("proto", "path", 1, 1, "input {stdin{}} output{stdout{}}");
        final ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        final PipelineIR pipelineIR =
                ConfigCompiler.configToPipelineIR(Collections.singletonList(swm), false, cve);
        assertThat(pipelineIR.getOutputPluginVertices().size(), is(1));
        assertThat(pipelineIR.getFilterPluginVertices().size(), is(0));
    }

    /**
     * Tests that repeatedly parsing the same config (containing a large number of duplicated sections)
     * into a {@link Graph} repeatedly results in a graph with a constant (i.e. deterministic)
     * hash code as returned by {@link Graph#uniqueHash()}.
     *
     * @throws Exception On Failure
     */
    @Test
    public void testConfigDuplicateBlocksToPipelineIR() throws Exception {
        final String condition = "if [message] == 'foo' {\nif [message] == 'foo' {drop {}}}\n";
        final StringBuilder source = new StringBuilder().append("filter {\n");
        for (int i = 0; i < 100; ++i) {
            source.append(condition);
        }
        final String config = source.append('}').toString();
        final String first = graphHash(config);
        for (int run = 0; run < 5; ++run) {
            assertThat(graphHash(config), is(first));
        }
    }

    /**
     * Tests that repeatedly parsing the same complex config String into a {@link Graph} repeatedly
     * results in a graph with a constant (i.e. deterministic) hash code as returned by
     * {@link Graph#uniqueHash()}.
     *
     * @throws Exception On Failure
     */
    @Test
    public void testComplexConfigToPipelineIR() throws Exception {
        final ByteArrayOutputStream baos = new ByteArrayOutputStream();
        try (final InputStream src = getClass().getResourceAsStream("complex.cfg")) {
            int read;
            final byte[] buffer = new byte[1024];
            while ((read = src.read(buffer)) >= 0) {
                baos.write(buffer, 0, read);
            }
        }
        final String config = baos.toString("UTF-8");
        final String first = graphHash(config);
        assertThat(graphHash(config), is(first));
    }

    private static String graphHash(final String config) throws InvalidIRException {
        SourceWithMetadata swm = new SourceWithMetadata("proto", "path", 1, 1, config);
        final ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
        return ConfigCompiler.configToPipelineIR(Collections.singletonList(swm), false, cve).uniqueHash();
    }

    @Test
    public void testCompileWithAnEmptySource() throws InvalidIRException {
        List<SourceWithMetadata> sourcesWithMetadata = Arrays.asList(
                new SourceWithMetadata("str", "in_plugin", 0, 0, "input { input_0 {} } "),
                new SourceWithMetadata("str", "out_plugin", 0, 0, "output { output_0 {} } "),
                new SourceWithMetadata("str", "<empty>", 0, 0, "     ")
        );

        PipelineIR pipeline = ConfigCompiler.compileSources(sourcesWithMetadata, false, null);

        assertEquals("should compile only the text parts", 2L, pipeline.pluginVertices().count());
    }

    @Test
    public void testCompileWithFullyCommentedSource() throws InvalidIRException {
        List<SourceWithMetadata> sourcesWithMetadata = Arrays.asList(
                new SourceWithMetadata("str", "in_plugin", 0, 0, "input { input_0 {} } "),
                new SourceWithMetadata("str","commented_filter",0,0,"#filter{...}\n"),
                new SourceWithMetadata("str","out_plugin",0,0,"output { output_0 {} } ")
        );

        PipelineIR pipeline = ConfigCompiler.compileSources(sourcesWithMetadata, false, null);

        assertEquals("should compile only non commented text parts", 2L, pipeline.pluginVertices().count());
    }

    @Test
    public void testCompilingPipelineWithMultipleSources() throws InvalidIRException {
        String sourceId = "fake_sourcefile";
        String sourceProtocol = "test_proto";
        SourceWithMetadata sourceWithMetadata = new SourceWithMetadata(sourceProtocol, sourceId, 0, 0, "booo");

        String[] sources = new String[] {
                "input { input_0 {} } filter { filter_0 {} } output { output_0 {} }",
                "input { input_1 {} } filter { filter_1 {} } output { output_1 {} }"};

        List<SourceWithMetadata> sourcesWithMetadata = Arrays.asList(
                new SourceWithMetadata(sourceProtocol + "_" + 0, sourceId + "_" + 0, 0, 0, sources[0]),
                new SourceWithMetadata(sourceProtocol + "_" + 1, sourceId + "_" + 1, 0, 0, sources[1]));

        PipelineIR pipeline = ConfigCompiler.compileSources(sourcesWithMetadata, false, null);

        assertFalse("should generate a hash", pipeline.uniqueHash().isEmpty());
        assertEquals("should provide the original source", String.join("\n", sources),
                pipeline.getOriginalSource());
        verifyApplyingProtocolAndIdMetadata(pipeline);
    }

    private void verifyApplyingProtocolAndIdMetadata(PipelineIR pipeline) {
        for (PluginVertex pv : pipeline.getPluginVertices()) {
            String nameIdx = last(pv.getPluginDefinition().getName().split("_"));
            String sourceProtocolIdx = last(pv.getSourceWithMetadata().getProtocol().split("_"));
            String sourceIdIdx = last(pv.getSourceWithMetadata().getId().split("_"));
            assertEquals("should apply the correct source metadata to protocol", nameIdx, sourceProtocolIdx);
            assertEquals("should apply the correct source metadata to id", nameIdx, sourceIdIdx);
        }
    }

    private static String last(String[] s) {
        return s[s.length - 1];
    }

    @Test
    public void testComplexConfigs() throws IOException {
        Path path = Paths.get(".").toAbsolutePath().resolve("../spec/support/lscl_configs").normalize();
        Files.list(path).forEach(this::verifyComplexConfig);
    }

    private void verifyComplexConfig(Path path) {
        String configName = path.getFileName().toString();

        String source = null;
        try {
            source = new String(Files.readAllBytes(path));
        } catch (IOException e) {
            fail(configName + " not readable");
        }

        PipelineIR pipelineIR = null;
        try {
            SourceWithMetadata sourceWithMetadata = new SourceWithMetadata("test_proto", "fake_sourcefile", 0, 0, source);
            ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());
            pipelineIR = ConfigCompiler.compileSources(Collections.singletonList(sourceWithMetadata), false, cve);
        } catch (InvalidIRException iirex) {
            fail("error compiling " + configName + ": " + iirex.getMessage());
        }

        assertNotNull(configName + " should compile", pipelineIR);
        assertFalse(configName + " should have a hash", pipelineIR.uniqueHash().isEmpty());
    }
}
