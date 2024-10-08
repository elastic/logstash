package org.logstash.health;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Test;
import org.junit.experimental.runners.Enclosed;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.junit.runners.Parameterized.Parameter;
import org.junit.runners.Parameterized.Parameters;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.EnumSet;
import java.util.List;
import java.util.stream.Collectors;

import static com.google.common.collect.Collections2.orderedPermutations;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.CoreMatchers.equalTo;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.logstash.health.Status.*;

@RunWith(Enclosed.class)
public class StatusTest {

    public static class Tests {
        @Test
        public void testReduceUnknown() {
            assertThat(UNKNOWN.reduce(UNKNOWN), is(UNKNOWN));
            assertThat(UNKNOWN.reduce(GREEN), is(UNKNOWN));
            assertThat(UNKNOWN.reduce(YELLOW), is(YELLOW));
            assertThat(UNKNOWN.reduce(RED), is(RED));
        }

        @Test
        public void testReduceGreen() {
            assertThat(GREEN.reduce(UNKNOWN), is(UNKNOWN));
            assertThat(GREEN.reduce(GREEN), is(GREEN));
            assertThat(GREEN.reduce(YELLOW), is(YELLOW));
            assertThat(GREEN.reduce(RED), is(RED));
        }

        @Test
        public void testReduceYellow() {
            assertThat(YELLOW.reduce(UNKNOWN), is(YELLOW));
            assertThat(YELLOW.reduce(GREEN), is(YELLOW));
            assertThat(YELLOW.reduce(YELLOW), is(YELLOW));
            assertThat(YELLOW.reduce(RED), is(RED));
        }

        @Test
        public void testReduceRed() {
            assertThat(RED.reduce(UNKNOWN), is(RED));
            assertThat(RED.reduce(GREEN), is(RED));
            assertThat(RED.reduce(YELLOW), is(RED));
            assertThat(RED.reduce(RED), is(RED));
        }
    }

    @RunWith(Parameterized.class)
    public static class JacksonSerialization {
        @Parameters(name = "{0}")
        public static Iterable<?> data() {
            return EnumSet.allOf(Status.class);
        }

        @Parameter
        public Status status;

        private final ObjectMapper mapper = new ObjectMapper();

        @Test
        public void testSerialization() throws Exception {
            assertThat(mapper.writeValueAsString(status), is(equalTo('"' + status.name().toLowerCase() + '"')));
        }
    }

    @RunWith(Parameterized.class)
    public static class ReduceCommutativeSpecification {
        @Parameters(name = "{0}<=>{1}")
        public static Collection<Object[]> data() {
            return getCombinations(EnumSet.allOf(Status.class), 2);
        }

        @Parameter(0)
        public Status statusA;
        @Parameter(1)
        public Status statusB;

        @Test
        public void testReduceCommutative() {
            assertThat(statusA.reduce(statusB), is(statusB.reduce(statusA)));
        }

        private static <T extends Comparable<T>> List<Object[]> getCombinations(Collection<T> source, int count) {
            return orderedPermutations(source).stream()
                    .map((l) -> l.subList(0, count))
                    .map(ArrayList::new).peek(Collections::sort)
                    .collect(Collectors.toSet())
                    .stream()
                    .map(List::toArray)
                    .collect(Collectors.toList());
        }
    }
}