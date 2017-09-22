package org.logstash.common.parser;

import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.List;

class ConstructorExample {
    static final ConstructingObjectParser<ConstructorExample> BUILDER = new ConstructingObjectParser<>(
            ConstructorExample::new,
            Field.declareInteger("integer"),
            Field.declareFloat("float"),
            Field.declareLong("long"),
            Field.declareDouble("double"),
            Field.declareBoolean("boolean"),
            Field.declareString("string"),
            Field.declareField("path", object -> Paths.get(ObjectTransforms.transformString(object))),
            Field.declareList("list", ObjectTransforms::transformString)
    );

    private Path path;
    private final int i;
    private final float f;
    private final double d;
    private final boolean b;
    private final long l;
    private final String s;
    private final Path p;
    private final List<String> stringList;

    private ConstructorExample(int i, float f, long l, double d, boolean b, String s, Path p, List<String> stringList) {
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

    float getF() {
        return f;
    }

    double getD() {
        return d;
    }

    boolean isB() {
        return b;
    }

    long getL() {
        return l;
    }

    String getS() {
        return s;
    }

    Path getP() {
        return p;
    }

    List<String> getStringList() {
        return stringList;
    }

    public Path getPath() {
        return path;
    }
}
