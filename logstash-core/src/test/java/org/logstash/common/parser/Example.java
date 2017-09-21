package org.logstash.common.parser;

import java.nio.file.Path;
import java.util.List;

class Example {
    private Path path;
    private int i;
    private float f;
    private double d;
    private boolean b;
    private long l;
    private String s;
    private Path p;
    private List<String> stringList;

    Example() {
    }

    Example(int i, float f, long l, double d, boolean b, String s, Path p, List<String> stringList) {
        this.i = i;
        this.f = f;
        this.l = l;
        this.d = d;
        this.b = b;
        this.s = s;
        this.p = p;
        this.stringList = stringList;
    }

    int getI() {
        return i;
    }

    void setI(int i) {
        this.i = i;
    }

    float getF() {
        return f;
    }

    void setF(float f) {
        this.f = f;
    }

    double getD() {
        return d;
    }

    void setD(double d) {
        this.d = d;
    }

    boolean isB() {
        return b;
    }

    void setB(boolean b) {
        this.b = b;
    }

    long getL() {
        return l;
    }

    void setL(long l) {
        this.l = l;
    }

    String getS() {
        return s;
    }

    void setS(String s) {
        this.s = s;
    }

    Path getP() {
        return p;
    }

    void setP(Path p) {
        this.p = p;
    }

    List<String> getStringList() {
        return stringList;
    }

    void setStringList(List<String> stringList) {
        this.stringList = stringList;
    }

    public Path getPath() {
        return path;
    }

    public void setPath(Path path) {
        this.path = path;
    }
}
