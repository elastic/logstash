package org.logstash.common.parser;

public class NestedExample {
    static final ConstructingObjectParser<NestedExample> BUILDER = new ConstructingObjectParser<>(
            NestedExample::new,
            Field.declareObject("foo", Nested.BUILDER)
    );
    private final Nested nested;

    private NestedExample(Nested nested) {
        this.nested = nested;
    }

    public Nested getNested() {
        return nested;
    }

    public static class Nested {
        static final ConstructingObjectParser<Nested> BUILDER = new ConstructingObjectParser<>(Nested::new, Field.declareInteger("i"));

        private final int i;

        Nested(int i) {
            this.i = i;
        }

        public int getI() {
            return i;
        }
    }

}
