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

import com.google.common.io.Files;
import org.hamcrest.MatcherAssert;
import org.jruby.RubyArray;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.EnvironmentVariableProvider;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.unary.Truthy;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.config.ir.graph.algorithms.GraphDiff;
import org.logstash.plugins.ConfigVariableExpander;

import java.io.File;
import java.io.IOException;
import java.net.URL;
import java.nio.charset.Charset;
import java.util.*;
import java.util.concurrent.Callable;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.PluginDefinition.Type.*;

public class IRHelpers {
    public static void assertSyntaxEquals(SourceComponent left, SourceComponent right) {
        String message = String.format("Expected '%s' to equal '%s'", left, right);
        MatcherAssert.assertThat(message, left.sourceComponentEquals(right));
    }

    public static void assertSyntaxEquals(Graph left, Graph right) {
        String message = String.format("Expected \n'%s'\n to equal \n'%s'\n%s", left, right, GraphDiff.diff(left, right));
        MatcherAssert.assertThat(message, left.sourceComponentEquals(right));
    }

    public static Vertex createTestVertex() {
        return createTestVertex(UUID.randomUUID().toString());
    }

    public static Vertex createTestVertex(String id) {
        return createTestVertex(randMeta(), id);
    }

    public static Vertex createTestVertex(SourceWithMetadata meta, String id) {
        return new TestVertex(meta, id);
    }

    static class TestVertex extends Vertex {
        private String id;

        public TestVertex(SourceWithMetadata meta, String id) {
            super(meta, id);
            this.id = id;
        }

        @Override
        public Vertex copy() {
            return new TestVertex(this.getSourceWithMetadata(), id);
        }

        @Override
        public String getId() {
            return this.id;
        }

        public String toString() {
            return "TestVertex-" + id;
        }

        @Override
        public boolean sourceComponentEquals(SourceComponent other) {
            if (other == null) return false;
            if (other instanceof TestVertex) {
                return Objects.equals(getId(), ((TestVertex) other).getId());
            }
            return false;
        }
    }

    public static Edge createTestEdge() throws InvalidIRException {
        Vertex v1 = createTestVertex();
        Vertex v2 = createTestVertex();
        return new TestEdge(v1,v2);

    }

    public static Edge createTestEdge(Vertex from, Vertex to) throws InvalidIRException {
        return new TestEdge(from, to);
    }

    public static final class TestEdge extends Edge {
        TestEdge(Vertex from, Vertex to) throws InvalidIRException {
            super(from, to);
        }

        @Override
        public Edge copy(Vertex from, Vertex to) throws InvalidIRException {
            return new TestEdge(from, to);
        }

        @Override
        public String individualHashSource() {
            return "TEdge";
        }

        @Override
        public String getId() {
            return individualHashSource();
        }
    }

    public static BooleanExpression createTestExpression() throws InvalidIRException {
        return new Truthy(null, new ValueExpression(null, 1));
    }

    public static SourceWithMetadata testMetadata() throws IncompleteSourceWithMetadataException {
        return new SourceWithMetadata("file", "/fake/file", 1, 2, "<fakesource>");
    }

    public static PluginDefinition testPluginDefinition() {
        return new PluginDefinition(PluginDefinition.Type.FILTER, "testDefinition", new HashMap<String, Object>());
    }

    public static PipelineIR samplePipeline() throws Exception {
        Random rng = new Random(81892198);
        Callable<SourceWithMetadata> meta = () -> randMeta(rng);
        ConfigVariableExpander cve = ConfigVariableExpander.withoutSecret(EnvironmentVariableProvider.defaultProvider());

        Graph inputSection = iComposeParallel(iPlugin(meta.call(), INPUT, "generator"), iPlugin(meta.call(), INPUT, "stdin")).toGraph(null);
        Graph filterSection = iIf(meta.call(), eEq(eEventValue("[foo]"), eEventValue("[bar]")),
                                    iPlugin(meta.call(), FILTER, "grok"),
                                    iPlugin(meta.call(), FILTER, "kv")).toGraph(cve);
        Graph outputSection = iIf(meta.call(), eGt(eEventValue("[baz]"), eValue(1000)),
                                    iComposeParallel(
                                            iPlugin(meta.call(), OUTPUT, "s3"),
                                            iPlugin(meta.call(), OUTPUT, "elasticsearch")),
                                    iPlugin(meta.call(), OUTPUT, "stdout")).toGraph(cve);

        return new PipelineIR(inputSection, filterSection, outputSection);
    }

    public static SourceWithMetadata randMeta() {
        try {
            return randMeta(new Random());
        } catch (IncompleteSourceWithMetadataException e) {
            // Never happens, or if it does, the whole test suite is broken anyway
            throw new RuntimeException(e);
        }
    }

    public static SourceWithMetadata randMeta(Random rng) throws IncompleteSourceWithMetadataException {
        return new SourceWithMetadata(
                        randomString(rng, 10),
                        randomString(rng, 10),
                        rng.nextInt(),
                        rng.nextInt(),
                        randomString(rng, 20)
                    );
    }

    public static String RANDOM_CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890";

    public static String randomString(Random rng, int length) {
        StringBuilder out = new StringBuilder();
        for (int i = 0; i < length; i++) {
            int pos = Math.abs(rng.nextInt()) % RANDOM_CHARS.length();
            out.append(RANDOM_CHARS.charAt(pos));
        }
        return out.toString();
    }


    @SuppressWarnings("rawtypes")
    public static RubyArray toSourceWithMetadata(String config) throws IncompleteSourceWithMetadataException {
        return RubyUtil.RUBY.newArray(JavaUtil.convertJavaToRuby(
                RubyUtil.RUBY, new SourceWithMetadata("proto", "path", 1, 1, config)));
    }

    /**
     * Load pipeline configuration from a path returning the list of SourceWithMetadata.
     *
     * The path refers to test's resources, if it point to single file that file is loaded, if reference a directory
     * then the full list of contained files is loaded in name order.
     * */
    @SuppressWarnings("rawtypes")
    public static RubyArray toSourceWithMetadataFromPath(String configPath) throws IncompleteSourceWithMetadataException, IOException {
        URL url = IRHelpers.class.getClassLoader().getResource(configPath);
        String path = url.getPath();
        final File filePath = new File(path);
        final List<File> files;
        if (filePath.isDirectory()) {
            files = Arrays.asList(filePath.listFiles());
            Collections.sort(files);
        } else {
            files = Collections.singletonList(filePath);
        }

        List<IRubyObject> rubySwms = new ArrayList<>();
        for (File configFile : files) {
            final List<String> fileContent = Files.readLines(configFile, Charset.defaultCharset());
            final SourceWithMetadata swm = new SourceWithMetadata("file", configFile.getPath(), 1, 1, String.join("\n", fileContent));
            rubySwms.add(JavaUtil.convertJavaToRuby(RubyUtil.RUBY, swm));
        }
        return RubyUtil.RUBY.newArray(rubySwms);
    }
}
