package org.logstash.plugin;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

enum Conversion {
    String,
    Integer,
    Float,
    Boolean;

    static Optional<Conversion> lookup(String value) {
        return Arrays.stream(Conversion.values()).filter(c -> c.toString().toLowerCase().equals(value.toLowerCase())).findFirst();
    }

    static List<String> names() {
        return Arrays.stream(Conversion.values()).map(Object::toString).map(java.lang.String::toLowerCase).collect(Collectors.toList());
    }

    Object convert(Object value) {
        switch (this) {
            case String:
                return value.toString();
            case Integer:
                return java.lang.Integer.parseInt((String) value);
            case Float:
                return java.lang.Float.parseFloat((String) value);
            case Boolean:
                switch (((String) value).toLowerCase()) {
                    case "true":
                        return true;
                    case "false":
                        return false;
                    default:
                        throw new IllegalArgumentException("Boolean convert only works on values 'true' or 'false' (case insensitive)");
                }
        }

        assert (false); // should not get here
        throw new IllegalArgumentException("BUG: Unreachable code has been reached.");
    }
}
