package org.logstash.config.ir;

import org.hamcrest.MatcherAssert;
import org.logstash.config.ir.graph.Edge;
import org.logstash.config.ir.graph.Graph;

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
        String message = String.format("Expected '%s' to equal '%s'\n%s", left, right, left.diff(right));

        MatcherAssert.assertThat(message, left.sourceComponentEquals(right));
    }




}
