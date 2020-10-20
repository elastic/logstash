package org.logstash.util;

public final class ByteValue {

    public static int parse(String s) {
        //TODO reimplement this in generic way
        if (s.matches("(?:k|kb)$")) {
            return Integer.parseInt(s.substring(0, s.indexOf("kb"))) * 1024;
        } else if (s.matches("(?:m|mb)$")) {
            return Integer.parseInt(s.substring(0, s.indexOf("mb"))) * 1024 * 1024;
        } else if (s.matches("(?:g|gb)$")) {
            return Integer.parseInt(s.substring(0, s.indexOf("gb"))) * 1024 * 1024 * 1024;
        } else if (s.matches("(?:t|tb)$")) {
            return Integer.parseInt(s.substring(0, s.indexOf("tb"))) * 1024 * 1024 * 1024 * 1024;
        } else if (s.matches("(?:p|pb)$")) {
            return Integer.parseInt(s.substring(0, s.indexOf("pb"))) * 1024 * 1024 * 1024 * 1024 * 1024;
        } else if (s.matches("(?:b)$")) {
            return Integer.parseInt(s.substring(0, s.indexOf("b")));
        } else {
            throw new IllegalArgumentException("Unknown bytes value '" + s + "'");
        }
    }

    public static boolean isSizeMeasure(String s) {
        if (s.matches("(?:k|kb)$")) {
            return true;
        } else if (s.matches("(?:m|mb)$")) {
            return true;
        } else if (s.matches("(?:g|gb)$")) {
            return true;
        } else if (s.matches("(?:t|tb)$")) {
            return true;
        } else if (s.matches("(?:p|pb)$")) {
            return true;
        } else if (s.matches("(?:b)$")) {
            return true;
        } else {
            return false;
        }
    }
}
