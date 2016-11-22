package org.logstash.config.ir;

import org.hamcrest.MatcherAssert;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.unary.Truthy;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;
import org.logstash.config.ir.graph.algorithms.GraphDiff;

import java.util.HashMap;
import java.util.Objects;
import java.util.UUID;

import static org.logstash.config.ir.DSL.*;
import static org.logstash.config.ir.PluginDefinition.Type.*;

/**
 * Created by andrewvc on 9/19/16.
 */
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
        return new TestVertex(id);
    }

    static class TestVertex extends Vertex {
        private String id;

        public TestVertex(String id) {
            this.id = id;
        }

        @Override
        public Vertex copy() {
            return new TestVertex(id);
        }

        @Override
        public String individualHashSource() {
            return "TVertex" + "|" + id;
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

        @Override
        public SourceMetadata getMeta() {
            return null;
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

    public static SourceMetadata testMetadata() {
        return new SourceMetadata("/fake/file", 1, 2, "<fakesource>");
    }

    public static PluginDefinition testPluginDefinition() {
        return new PluginDefinition(PluginDefinition.Type.FILTER, "testDefinition", new HashMap<String, Object>());
    }

    public static Pipeline samplePipeline() throws InvalidIRException {
        Graph inputSection = iComposeParallel(iPlugin(INPUT, "generator"), iPlugin(INPUT, "stdin")).toGraph();
        Graph filterSection = iIf(eEq(eEventValue("[foo]"), eEventValue("[bar]")),
                                    iPlugin(FILTER, "grok"),
                                    iPlugin(FILTER, "kv")).toGraph();
        Graph outputSection = iIf(eGt(eEventValue("[baz]"), eValue(1000)),
                                    iComposeParallel(
                                            iPlugin(OUTPUT, "s3"),
                                            iPlugin(OUTPUT, "elasticsearch")),
                                    iPlugin(OUTPUT, "stdout")).toGraph();

        return new Pipeline(inputSection, filterSection, outputSection);
    }
}
