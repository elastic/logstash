package org.logstash.common.parser;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

class FieldExample {
    static final ObjectFactory<FieldExample> BUILDER = new ObjectFactory<>(FieldExample::new)
            .define(Field.declareInteger("integer"), FieldExample::setI)
            .define(Field.declareFloat("float"), FieldExample::setF)
            .define(Field.declareDouble("double"), FieldExample::setD)
            .define(Field.declareLong("long"), FieldExample::setL)
            .define(Field.declareBoolean("boolean"), FieldExample::setB)
            .define(Field.declareString("string"), FieldExample::setS)
            .define(Field.declareField("path", (object) -> Paths.get(ObjectTransforms.transformString(object))), FieldExample::setP)
            .define(Field.declareList("list", ObjectTransforms::transformString), FieldExample::setStringList);

    private int i;
    private float f;
    private double d;
    private boolean b;
    private long l;
    private String s;
    private Path p;
    private List<String> stringList;

    public int getI() {
        return i;
    }

    private void setI(int i) {
        this.i = i;
    }

    float getF() {
        return f;
    }

    private void setF(float f) {
        this.f = f;
    }

    double getD() {
        return d;
    }

    private void setD(double d) {
        this.d = d;
    }

    boolean isB() {
        return b;
    }

    private void setB(boolean b) {
        this.b = b;
    }

    long getL() {
        return l;
    }

    private void setL(long l) {
        this.l = l;
    }

    public String getS() {
        return s;
    }

    private void setS(String s) {
        this.s = s;
    }

    Path getP() {
        return p;
    }

    private void setP(Path p) {
        this.p = p;
    }

    List<String> getStringList() {
        return stringList;
    }

    private void setStringList(List<String> stringList) {
        this.stringList = stringList;
    }
}
