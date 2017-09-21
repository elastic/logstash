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
import java.util.function.BiConsumer;

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

    public static class MixedUsageTest {
        private Map<String, Object> config = new HashMap<>();
        private int foo = 1000; // XXX: randomize
        private String bar = "hello"; // XXX: randomize

        @Before
        public void setup() {
            config.put("foo", foo);
            config.put("bar", bar);
        }

        @Test
        public void testGoodConstruction() {
            MixedExample example = MixedExample.BUILDER.apply(config);
            assertEquals(foo, example.getFoo());
            assertEquals(bar, example.getBar());
        }
    }

    public static class FieldIntegrationTest {
        private final ConstructingObjectParser<Example> EXAMPLE_BUILDER = new ConstructingObjectParser<>(Example::new);
        private final ConstructingObjectParser<Path> PATH_BUILDER = new ConstructingObjectParser<Path>(Paths::get, Field.declareString("path"));

        private final Map<String, Object> config = new HashMap<>();


        @Before
        public void setup() {
            check(EXAMPLE_BUILDER.declareFloat("float", Example::setF));
            check(EXAMPLE_BUILDER.declareInteger("integer", Example::setI));
            check(EXAMPLE_BUILDER.declareLong("long", Example::setL));
            check(EXAMPLE_BUILDER.declareDouble("double", Example::setD));
            check(EXAMPLE_BUILDER.declareBoolean("boolean", Example::setB));
            check(EXAMPLE_BUILDER.declareString("string", Example::setS));
            check(EXAMPLE_BUILDER.declareList("stringList", Example::setStringList, ObjectTransforms::transformString));

            // Custom transform (Object => Path)
            check(EXAMPLE_BUILDER.declareString("path", (example, path) -> example.setP(Paths.get(path))));

            // Custom nested object constructor: { "object": { "path": "some path" } }
            //check(EXAMPLE_BUILDER.declareObject("object", Example::setP2, PATH_BUILDER));

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
            assertNull(e.getP());
        }

        @Test
        public void testCustomTransform() {
            config.put("path", "example");
            Example e = EXAMPLE_BUILDER.apply(config);
            assertEquals(Paths.get("example"), e.getP());
        }

        @Test
        public void testNestedObject() {
            config.put("object", Collections.singletonMap("path", "example"));
            Example e = EXAMPLE_BUILDER.apply(config);
            //assertEquals(Paths.get("example"), e.getP2());
        }

        @Test(expected = IllegalArgumentException.class)
        public void testDuplicateFieldsAreRejected() {
            // field 'float' is already defined, so this should fail.
            check(EXAMPLE_BUILDER.declareString("float", (a, b) -> {
            }));
        }
    }

    public static class ConstructorIntegrationTest {
        private final ConstructingObjectParser<Example> EXAMPLE_BUILDER = new ConstructingObjectParser<Example>(
                Example::new,
                Field.declareInteger("integer"), // arg0
                Field.declareFloat("float"), // arg0
                Field.declareLong("long"), // arg2 ...
                Field.declareDouble("double"),
                Field.declareBoolean("boolean"),
                Field.declareString("string"),
                Field.declareField("path", object -> Paths.get(ObjectTransforms.transformString(object))),
                Field.declareList("strings", ObjectTransforms::transformString)
        );

        private final ConstructingObjectParser<Path> PATH_BUILDER = new ConstructingObjectParser<>(Paths::get, Field.declareString("path"));

        private final Map<String, Object> config = new LinkedHashMap<>();

        @Before
        public void setup() {
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
            assertEquals(Paths.get("path"), e.getP());

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
            String name = "foo";
            new ConstructingObjectParser<Path>(Paths::get, Field.declareString(name), Field.declareString(name));
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
        final ConstructingObjectParser<Example> c = new ConstructingObjectParser<>(Example::new);
        final BiConsumer<Example, Integer> noOp = (a, b) -> { /* empty */ };

        @Before
        public void setup() {
            check(c.declareInteger("deprecated", noOp).setDeprecated("This setting will warn the user when used."));
            check(c.declareInteger("obsolete", noOp).setObsolete("This setting should cause a failure when someone uses it."));
        }

        private static class Example {
        }

        @Test
        public void deprecatedUsageIsAllowed() {
            // XXX: Implement a custom log appender that captures log4j logs so we can verify the warning is logged.
            c.apply(Collections.singletonMap("deprecated", 1));
        }

    }
}