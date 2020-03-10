package org.logstash;

import java.util.List;

public class KeyNode {

    private KeyNode() {
        // Utility Class
    }

    // TODO: (colin) this should be moved somewhere else to make it reusable
    //   this is a quick fix to compile on JDK7 a not use String.join that is
    //   only available in JDK8
    public static String join(List<?> list, String delim) {
        int len = list.size();

        if (len == 0) return "";

        final StringBuilder result = new StringBuilder(toString(list.get(0), delim));
        for (int i = 1; i < len; i++) {
            result.append(delim);
            result.append(toString(list.get(i), delim));
        }
        return result.toString();
    }

    private static String toString(Object value, String delim) {
        if (value == null) return "";
        if (value instanceof List) return join((List)value, delim);
        return value.toString();
    }
}
