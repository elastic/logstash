package org.logstash.plugin;

import org.junit.Test;
import org.junit.experimental.runners.Enclosed;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;
import org.logstash.plugin.example.ExampleInput;
import org.logstash.plugin.example.ExamplePlugin;

import java.util.*;

import static org.junit.Assert.assertEquals;
import static org.junit.runners.Parameterized.Parameters;

@RunWith(Enclosed.class)
public class ConstructingObjectParserTest {
    public static class ExampleInputTest {
        @Test
        public void testExample() {
            Plugin example = new ExamplePlugin();
            Map<String, ConstructingObjectParser<? extends Input>> inputs = example.getInputs();
            ConstructingObjectParser<? extends Input> inputConstructor = inputs.get("example");

            Map<String, Object> config = new TreeMap<>();
            config.put("port", 5000);

            Map<String, Object> tlsConfig = new TreeMap<>();
            tlsConfig.put("truststore", "/path/to/trust");
            config.put("tls", tlsConfig);

            ExampleInput input = (ExampleInput) inputConstructor.apply(config);
            System.out.println(input.getClass().getCanonicalName());
            System.out.println(input.getTLS().getClass().getCanonicalName());
        }
    }
    public static class IntegrationTest {
        @Test
        public void testParsing() {
            ConstructingObjectParser<Example> c = new ConstructingObjectParser<>((args) -> new Example());
            c.integer("foo", Example::setValue);

            Map<String, Object> config = Collections.singletonMap("foo", 1);

            Example e = c.apply(config);
            assertEquals(1, e.getValue());
        }

        private class Example {
            private int i;

            public Example() {
            }

            int getValue() {
                return i;
            }

            void setValue(int i) {
                this.i = i;
            }
        }
    }

    @RunWith(Parameterized.class)
    public static class StringAccepts {
        private final Object input;
        private final Object expected;

        public StringAccepts(Object input, Object expected) {
            this.input = input;
            this.expected = expected;
        }

        @Parameters
        public static Collection<Object[]> data() {
            return Arrays.asList(new Object[][]{
                    {"1", "1"},
                    {1, "1"},
                    {1L, "1"},
                    {1F, "1.0"},
                    {1D, "1.0"},
            });
        }

        @Test
        public void testStringTransform() {
            String value = ConstructingObjectParser.stringTransform(input);
            assertEquals(expected, value);

        }
    }

    @RunWith(Parameterized.class)
    public static class StringRejections {
        private Object input;

        public StringRejections(Object input) {
            this.input = input;
        }

        @Parameters
        public static List<Object> data() {
            return Arrays.asList(
                    new Object(),
                    Collections.emptyMap(),
                    Collections.emptyList()
            );
        }

        @Test(expected = IllegalArgumentException.class)
        public void testFailure() {
            ConstructingObjectParser.stringTransform(input);
        }
    }
}