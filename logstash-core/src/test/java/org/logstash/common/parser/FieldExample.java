package org.logstash.common.parser;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

class FieldExample {
    public static final ConstructingObjectParser<FieldExample> BUILDER = new ConstructingObjectParser<>(FieldExample::new);

    static {
        BUILDER.declareInteger("integer", FieldExample::setI);
        BUILDER.declareFloat("float", FieldExample::setF);
        BUILDER.declareDouble("double", FieldExample::setD);
        BUILDER.declareLong("long", FieldExample::setL);
        BUILDER.declareBoolean("boolean", FieldExample::setB);
        BUILDER.declareString("string", FieldExample::setS);
        BUILDER.declareField("path", FieldExample::setP, (object) -> Paths.get(ObjectTransforms.transformString(object)));
        BUILDER.declareList("list", FieldExample::setStringList, ObjectTransforms::transformString);
    }

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
