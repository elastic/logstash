package org.logstash.config.ir;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.util.Arrays;
import java.util.List;

import org.apache.commons.codec.binary.StringUtils;
import org.assertj.core.util.Strings;
import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.PluginVertex;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;

public class ConfigCompilerTest extends RubyEnvTestCase {

    @Test
    public void testConfigToPipelineIR() throws Exception {
        final PipelineIR pipelineIR =
            ConfigCompiler.configToPipelineIR("input {stdin{}} output{stdout{}}", false);
        assertThat(pipelineIR.getOutputPluginVertices().size(), is(1));
        assertThat(pipelineIR.getFilterPluginVertices().size(), is(0));
    }

    /**
     * Tests that repeatedly parsing the same config (containing a large number of duplicated sections)
     * into a {@link Graph} repeatedly results in a graph with a constant (i.e. deterministic)
     * hash code as returned by {@link Graph#uniqueHash()}.
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

    private static String graphHash(final String config)
        throws IncompleteSourceWithMetadataException {
        return ConfigCompiler.configToPipelineIR(config, false).uniqueHash();
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

        PipelineIR pipeline = ConfigCompiler.compileSources(sourcesWithMetadata, false);

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
}
