package org.logstash.common.parser;

class MixedExample {
    static final ObjectFactory<MixedExample> BUILDER = new ObjectFactory<>(MixedExample::new, Field.declareInteger("foo"))
            .define(Field.declareString("bar"), MixedExample::setBar);

    private int foo;
    private String bar;

    private MixedExample(int foo) {
        this.foo = foo;
    }


    public int getFoo() {
        return foo;
    }

    public String getBar() {
        return bar;
    }

    private void setBar(String bar) {
        this.bar = bar;
    }
}
