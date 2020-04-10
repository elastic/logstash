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
import java.io.InputStream;

import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.graph.Graph;

import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;

public class ConfigCompilerTest extends RubyEnvTestCase {

    @Test
    public void testConfigToPipelineIR() throws Exception {
        IRubyObject swm = JavaUtil.convertJavaToRuby(
                RubyUtil.RUBY, new SourceWithMetadata("proto", "path", 1, 1, "input {stdin{}} output{stdout{}}"));
        final PipelineIR pipelineIR =
            ConfigCompiler.configToPipelineIR(RubyUtil.RUBY.newArray(swm), false);
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

    private static String graphHash(final String config) throws IncompleteSourceWithMetadataException {
        IRubyObject swm = JavaUtil.convertJavaToRuby(
                RubyUtil.RUBY, new SourceWithMetadata("proto", "path", 1, 1, config));
        return ConfigCompiler.configToPipelineIR(RubyUtil.RUBY.newArray(swm), false).uniqueHash();
    }
}
