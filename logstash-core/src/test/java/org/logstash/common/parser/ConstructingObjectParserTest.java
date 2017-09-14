package org.logstash.common.parser;

import org.junit.Before;
import org.junit.Test;
import org.junit.experimental.runners.Enclosed;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;
import static org.junit.runners.Parameterized.Parameters;

@RunWith(Enclosed.class)
public class ConstructingObjectParserTest {
    @SuppressWarnings("unused")
    private static void check(Field field) {
        // Exists to do return type compile-time checks.
        // no body is needed
    }
    public static class FieldIntegrationTest {
        private final ConstructingObjectParser<Example> EXAMPLE_BUILDER = new ConstructingObjectParser<>(Example::new);
        private final ConstructingObjectParser<Path> PATH_BUILDER = new ConstructingObjectParser<>(args -> Paths.get((String) args[0]));

        private final Map<String, Object> config = new HashMap<>();


        @Before
        public void setup() {
            check(PATH_BUILDER.declareString("path"));
            check(EXAMPLE_BUILDER.declareFloat("float", Example::setF));
            check(EXAMPLE_BUILDER.declareInteger("integer", Example::setI));
            check(EXAMPLE_BUILDER.declareLong("long", Example::setL));
            check(EXAMPLE_BUILDER.declareDouble("double", Example::setD));
            check(EXAMPLE_BUILDER.declareBoolean("boolean", Example::setB));
            check(EXAMPLE_BUILDER.declareString("string", Example::setS));
            check(EXAMPLE_BUILDER.declareList("stringList", Example::setStringList, ObjectTransforms::transformString));

            // Custom transform (Object => Path)
            check(EXAMPLE_BUILDER.declareString("path", (example, path) -> example.setP1(Paths.get(path))));

            // Custom nested object constructor: { "object": { "path": "some path" } }
            check(EXAMPLE_BUILDER.declareObject("object", Example::setP2, PATH_BUILDER));

            config.put("float", 1F);
            config.put("integer", 1);
            config.put("long", 1L);
            config.put("double", 1D);
            config.put("boolean", true);
            config.put("string", "hello");
            config.put("stringList", Collections.singletonList("hello"));
        }

        @Test
        public void testParsing() {
            Example e = EXAMPLE_BUILDER.apply(config);
            assertEquals(1F, e.getF(), 0.1);
            assertEquals(1D, e.getD(), 0.1);
            assertEquals(1, e.getI());
            assertEquals(1L, e.getL());
            assertEquals(true, e.isB());
            assertEquals("hello", e.getS());
            assertEquals(Collections.singletonList("hello"), e.getStringList());

            // because they are not set and the default in the Example class is null.
            assertNull(e.getP1());
            assertNull(e.getP2());
        }

        @Test
        public void testCustomTransform() {
            config.put("path", "example");
            Example e = EXAMPLE_BUILDER.apply(config);
            assertEquals(Paths.get("example"), e.getP1());
        }

        @Test
        public void testNestedObject() {
            config.put("object", Collections.singletonMap("path", "example"));
            Example e = EXAMPLE_BUILDER.apply(config);
            assertEquals(Paths.get("example"), e.getP2());
        }

        @Test(expected = UnsupportedOperationException.class)
        public void testInvalidConstructor() {
            // EXAMPLE_BUILDER gives a Supplier (not a Function<Object[], ...>), so constructor arguments
            // should be disabled and this call should fail.
            check(EXAMPLE_BUILDER.declareString("invalid"));
        }

        @Test(expected = IllegalArgumentException.class)
        public void testDuplicateFieldsAreRejected() {
            // field 'float' is already defined, so this should fail.
            check(EXAMPLE_BUILDER.declareString("float", (a, b) -> {
            }));
        }
    }

    public static class ConstructorIntegrationTest {
        private final ConstructingObjectParser<Example> EXAMPLE_BUILDER = new ConstructingObjectParser<>(args -> new Example((int) args[0], (float) args[1], (long) args[2], (double) args[3], (boolean) args[4], (String) args[5], (Path) args[6], (Path) args[7], (List<String>) args[8]));
        private final ConstructingObjectParser<Path> PATH_BUILDER = new ConstructingObjectParser<>(args -> Paths.get((String) args[0]));

        private final Map<String, Object> config = new LinkedHashMap<>();

        @Before
        public void setup() {
            check(PATH_BUILDER.declareString("path"));

            check(EXAMPLE_BUILDER.declareInteger("integer"));
            check(EXAMPLE_BUILDER.declareFloat("float"));
            check(EXAMPLE_BUILDER.declareLong("long"));
            check(EXAMPLE_BUILDER.declareDouble("double"));
            check(EXAMPLE_BUILDER.declareBoolean("boolean"));
            check(EXAMPLE_BUILDER.declareString("string"));

            // Custom transform (Object => Path)
            check(EXAMPLE_BUILDER.declareConstructorArg("path", (object) -> Paths.get((String) object)));

            // Custom nested object constructor: { "object": { "path": "some path" } }
            check(EXAMPLE_BUILDER.declareObject("object", PATH_BUILDER));

            check(EXAMPLE_BUILDER.declareList("stringList", ObjectTransforms::transformString));

            config.put("float", 1F);
            config.put("integer", 1);
            config.put("long", 1L);
            config.put("double", 1D);
            config.put("boolean", true);
            config.put("string", "hello");
            config.put("path", "path1");
            config.put("object", Collections.singletonMap("path", "path2"));
            config.put("stringList", Collections.singletonList("hello"));
        }

        @Test
        public void testParsing() {
            Example e = EXAMPLE_BUILDER.apply(config);
            assertEquals(1F, e.getF(), 0.1);
            assertEquals(1D, e.getD(), 0.1);
            assertEquals(1, e.getI());
            assertEquals(1L, e.getL());
            assertEquals(true, e.isB());
            assertEquals("hello", e.getS());
            assertEquals(Paths.get("path1"), e.getP1());
            assertEquals(Paths.get("path2"), e.getP2());

            assertEquals(Collections.singletonList("hello"), e.getStringList());
        }

        @Test(expected = IllegalArgumentException.class)
        public void testDuplicateFieldsAreRejected() {
            // field 'float' is already defined, so this should fail.
            check(EXAMPLE_BUILDER.declareString("float", (a, b) -> {
            }));
        }

        @Test(expected = IllegalArgumentException.class)
        public void testDuplicateConstructorFieldsAreRejected() {
            // field 'float' is already defined, so this should fail.
            check(EXAMPLE_BUILDER.declareString("float"));
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
            String value = ObjectTransforms.transformString(input);
            assertEquals(expected, value);

        }
    }

    @RunWith(Parameterized.class)
    public static class StringRejections {
        private final Object input;

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
            ObjectTransforms.transformString(input);
        }
    }

    public static class DeprecationsAndObsoletes {
        final ConstructingObjectParser<Example> c = new ConstructingObjectParser<>((args) -> new Example());

        @Before
        public void setup() {
            check(c.declareInteger("deprecated").setDeprecated("This setting will warn the user when used."));
            check(c.declareInteger("obsolete", (a, b) -> {
            }).setObsolete("This setting should cause a failure when someone uses it."));
        }

        @Test
        public void deprecatedUsageIsAllowed() {
            // XXX: Implement a custom log appender that captures log4j logs so we can verify the warning is logged.
            c.apply(Collections.singletonMap("deprecated", 1));
        }

        @Test(expected = IllegalArgumentException.class)
        public void obsoletesOnConstructorArgsIsInvalid() {
            c.declareInteger("fail").setObsolete("...");
        }

        private static class Example {
        }
    }
}