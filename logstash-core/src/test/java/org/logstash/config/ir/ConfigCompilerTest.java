package org.logstash.config.ir;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import org.junit.Test;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.config.ir.graph.Graph;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

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
}
