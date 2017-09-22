package org.logstash.common.parser;

import org.junit.Before;
import org.junit.Test;
import org.junit.experimental.runners.Enclosed;
import org.junit.runner.RunWith;
import org.junit.runners.Parameterized;

import java.nio.file.Paths;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.BiConsumer;

import static org.junit.Assert.*;
import static org.junit.runners.Parameterized.Parameters;

@RunWith(Enclosed.class)
public class ConstructingObjectParserTest {
    @SuppressWarnings("unused")
    private static void check(ObjectFactory<?> factory) {
        // Exists to do return type compile-time checks.
        // no body is needed
    }

    public static class MixedUsageTest {
        private final Map<String, Object> config = new HashMap<>();
        private final int foo = 1000; // XXX: randomize
        private final String bar = "hello"; // XXX: randomize

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

    public static class NestedTest {
        private final Map<String, Object> config = Collections.singletonMap("foo", Collections.singletonMap("i", 100));

        @Test
        public void testNested() {
            NestedExample e = NestedExample.BUILDER.apply(config);
            assertEquals(100, e.getNested().getI());
        }

        @Test
        public void testNestedSetter() {
            NestedExample e = NestedExample.BUILDER_USING_SETTERS.apply(config);
            assertEquals(100, e.getNested().getI());

        }

    }

    public static class FieldIntegrationTest {
        private final Map<String, Object> config = new HashMap<>();

        @Before
        public void setup() {
            config.put("integer", 1);
            config.put("float", 1F);
            config.put("double", 1D);
            config.put("long", 1L);
            config.put("boolean", true);
            config.put("string", "hello");
            config.put("list", Collections.singletonList("hello"));
        }

        @Test
        public void testParsing() {
            FieldExample e = FieldExample.BUILDER.apply(config);
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
            FieldExample e = FieldExample.BUILDER.apply(config);
            assertEquals(Paths.get("example"), e.getP());
        }

        @Test
        public void testNestedObject() {
            //config.put("object", Collections.singletonMap("path", "example"));
            //Example e = EXAMPLE_BUILDER.apply(config);
            //assertEquals(Paths.get("example"), e.getP2());
        }

        @Test(expected = IllegalArgumentException.class)
        public void testDuplicateFieldsAreRejected() {
            // field 'float' is already defined, so this should fail.
            check(FieldExample.BUILDER.define(Field.declareString("float"), (a, b) -> { /*empty*/ }));
        }
    }

    public static class ConstructorIntegrationTest {
        private final Map<String, Object> config = new LinkedHashMap<>();

        @Before
        public void setup() {
            config.put("float", 1F);
            config.put("integer", 1);
            config.put("long", 1L);
            config.put("double", 1D);
            config.put("boolean", true);
            config.put("string", "hello");
            config.put("path", "path");
            config.put("list", Collections.singletonList("hello"));
        }

        @Test
        public void testParsing() {
            ConstructorExample e = ConstructorExample.BUILDER.apply(config);
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
        public void testInvalidTypesAreRejected() {
            config.put("float", "Hello"); // put a string for the float field.
            ConstructorExample.BUILDER.apply(config); // should fail
        }

        @Test(expected = NullPointerException.class)
        public void testMissingArgumentsAreRejected() {
            config.remove("path");
            ConstructorExample.BUILDER.apply(config); // should fail

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
        static final BiConsumer<Object, Integer> noOp = (a, b) -> { /* empty */ };
        final ObjectFactory<Object> c = new ObjectFactory<>(Object::new);

        @Before
        public void setup() {
            check(c.deprecate(Field.declareInteger("deprecated"), noOp, "This thing is deprecated."));
            check(c.obsolete(Field.declareInteger("obsolete"), noOp, "This thing is obsolete."));
        }

        @Test
        public void deprecatedUsageIsAllowed() {
            // XXX: Implement a custom log appender that captures log4j logs so we can verify the warning is logged.
            c.apply(Collections.singletonMap("deprecated", 1));
        }

        @Test(expected = IllegalArgumentException.class)
        public void obsoleteUsageFails() {
            c.apply(Collections.singletonMap("obsolete", 1));
        }
    }

    @RunWith(Parameterized.class)
    public static class ConstructionArguments {
        static final ObjectFactory<List<Integer>> c0 = /* 0 args */ new ObjectFactory<>(Arrays::<Integer>asList);
        static final ObjectFactory<List<Integer>> c1 = /* 1 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"));
        static final ObjectFactory<List<Integer>> c2 = /* 2 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"), Field.declareInteger("a1"));
        static final ObjectFactory<List<Integer>> c3 = /* 3 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"), Field.declareInteger("a1"), Field.declareInteger("a2"));
        static final ObjectFactory<List<Integer>> c4 = /* 4 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"), Field.declareInteger("a1"), Field.declareInteger("a2"), Field.declareInteger("a3"));
        static final ObjectFactory<List<Integer>> c5 = /* 5 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"), Field.declareInteger("a1"), Field.declareInteger("a2"), Field.declareInteger("a3"), Field.declareInteger("a4"));
        static final ObjectFactory<List<Integer>> c6 = /* 6 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"), Field.declareInteger("a1"), Field.declareInteger("a2"), Field.declareInteger("a3"), Field.declareInteger("a4"), Field.declareInteger("a5"));
        static final ObjectFactory<List<Integer>> c7 = /* 7 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"), Field.declareInteger("a1"), Field.declareInteger("a2"), Field.declareInteger("a3"), Field.declareInteger("a4"), Field.declareInteger("a5"), Field.declareInteger("a6"));
        static final ObjectFactory<List<Integer>> c8 = /* 8 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"), Field.declareInteger("a1"), Field.declareInteger("a2"), Field.declareInteger("a3"), Field.declareInteger("a4"), Field.declareInteger("a5"), Field.declareInteger("a6"), Field.declareInteger("a7"));
        static final ObjectFactory<List<Integer>> c9 = /* 9 args */ new ObjectFactory<>(Arrays::<Integer>asList, Field.declareInteger("a0"), Field.declareInteger("a1"), Field.declareInteger("a2"), Field.declareInteger("a3"), Field.declareInteger("a4"), Field.declareInteger("a5"), Field.declareInteger("a6"), Field.declareInteger("a7"), Field.declareInteger("a8"));
        private final ObjectFactory<List<Integer>> builder;
        private final int i;

        public ConstructionArguments(ObjectFactory<List<Integer>> builder, int i) {
            this.builder = builder;
            this.i = i;
        }

        static Map<String, Object> genMap(int count) {
            Map<String, Object> map = new HashMap<>();
            for (int i = 0; i < count; i++) {
                map.put("a" + i, i);
            }
            return map;
        }

        @Parameters
        public static Collection<Object[]> data() {
            return Arrays.asList(new Object[][]{
                    {c0, 0},
                    {c1, 1},
                    {c2, 2},
                    {c3, 3},
                    {c4, 4},
                    {c5, 5},
                    {c6, 6},
                    {c7, 7},
                    {c8, 8},
                    {c9, 9},
            });
        }

        @Test
        public void testBuilder() {
            for (int args = 0; args <= 9; args++) {
                try {
                    builder.apply(genMap(args));
                } catch (IllegalArgumentException e) {
                    if (args < i) {
                        fail("Having fewer args than required should not generate an IllegalArgumentException");
                    }
                } catch (NullPointerException e) {
                    if (args >= i) {
                        fail("Having enough arguments should not generate a NullPointerException");
                    }
                }
            }
        }

    }
}