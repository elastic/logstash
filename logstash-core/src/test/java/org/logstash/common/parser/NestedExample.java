package org.logstash.common.parser;

public class NestedExample {
    static final ObjectFactory<NestedExample> BUILDER = new ObjectFactory<>(NestedExample::new, Field.declareObject("foo", Nested.BUILDER));

    static final ObjectFactory<NestedExample> BUILDER_USING_SETTERS = new ObjectFactory<>(NestedExample::new)
            .define(Field.declareObject("foo", Nested.BUILDER), NestedExample::setNested);

    private Nested nested;

    private NestedExample() {
    }
    private NestedExample(Nested nested) {
        this.nested = nested;
    }

    public Nested getNested() {
        return nested;
    }

    public void setNested(Nested nested) {
        this.nested = nested;
    }

    public static class Nested {
        static final ObjectFactory<Nested> BUILDER = new ObjectFactory<>(Nested::new, Field.declareInteger("i"));

        private final int i;

        Nested(int i) {
            this.i = i;
        }

        public int getI() {
            return i;
        }
    }

}
