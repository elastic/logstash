package org.logstash.config.ir;

import org.hamcrest.MatcherAssert;
import org.logstash.config.ir.expression.BooleanExpression;
import org.logstash.config.ir.expression.ValueExpression;
import org.logstash.config.ir.expression.unary.Truthy;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Graph;
import org.logstash.config.ir.graph.Vertex;

import java.util.stream.Stream;

/**
 * Created by andrewvc on 9/19/16.
 */
public class IRHelpers {
    public static void assertSyntaxEquals(ISourceComponent left, ISourceComponent right) {
        String message = String.format("Expected '%s' to equal '%s'", left, right);
        MatcherAssert.assertThat(message, left.sourceComponentEquals(right));
    }

    public static void assertGraphEquals(Graph left, Graph right) {
        String message = String.format("Expected \n'%s'\n to equal \n'%s'\n%s", left, right, left.diff(right));
        MatcherAssert.assertThat(message, left.sourceComponentEquals(right));
    }

    public static Vertex makeTestVertex() {
        return new Vertex() {
            @Override
            public boolean sourceComponentEquals(ISourceComponent sourceComponent) {
                return this.equals(sourceComponent);
            }
        };
    }

    public static Edge makeTestEdge() throws InvalidIRException {
        Vertex v1 = makeTestVertex();
        Vertex v2 = makeTestVertex();
        return new Edge(v1, v2) {};
    }

    public static Edge makeTestEdge(Vertex from, Vertex to) throws InvalidIRException {
        return new Edge(from, to) {};
    }

    public static BooleanExpression makeTestExpression() throws InvalidIRException {
        return new Truthy(null, new ValueExpression(null, 1));
    }
}
