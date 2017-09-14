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
    private Path p1;
    private Path p2;
    private List<String> stringList;

    Example() {
    }

    Example(int i, float f, long l, double d, boolean b, String s, Path p1, Path p2, List<String> stringList) {
        this.i = i;
        this.f = f;
        this.l = l;
        this.d = d;
        this.b = b;
        this.s = s;
        this.p1 = p1;
        this.p2 = p2;
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

    Path getP1() {
        return p1;
    }

    void setP1(Path p1) {
        this.p1 = p1;
    }

    Path getP2() {
        return p2;
    }

    void setP2(Path p2) {
        this.p2 = p2;
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
