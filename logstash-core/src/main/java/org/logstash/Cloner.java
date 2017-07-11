package org.logstash;

import java.util.*;

public final class Cloner {

    private Cloner(){}

    public static <T> T deep(final T input) {
        if (input instanceof Map<?, ?>) {
            return (T) deepMap((Map<?, ?>) input);
        } else if (input instanceof List<?>) {
            return (T) deepList((List<?>) input);
        } else if (input instanceof Collection<?>) {
            throw new ClassCastException("unexpected Collection type " + input.getClass());
        }

        return input;
    }

    private static <E> List<E> deepList(final List<E> list) {
        List<E> clone;
        if (list instanceof LinkedList<?>) {
            clone = new LinkedList<>();
        } else if (list instanceof ArrayList<?>) {
            clone = new ArrayList<>();
        } else if (list instanceof ConvertedList) {
            clone = new ArrayList<>();
        } else {
            throw new ClassCastException("unexpected List type " + list.getClass());
        }

        for (E item : list) {
            clone.add(deep(item));
        }

        return clone;
    }

    private static <K, V> Map<K, V> deepMap(final Map<K, V> map) {
        Map<K, V> clone;
        if (map instanceof LinkedHashMap<?, ?>) {
            clone = new LinkedHashMap<>();
        } else if (map instanceof TreeMap<?, ?>) {
            clone = new TreeMap<>();
        } else if (map instanceof HashMap<?, ?>) {
            clone = new HashMap<>();
        } else if (map instanceof ConvertedMap) {
            clone = new HashMap<>();
        } else {
            throw new ClassCastException("unexpected Map type " + map.getClass());
        }

        for (Map.Entry<K, V> entry : map.entrySet()) {
            clone.put(entry.getKey(), deep(entry.getValue()));
        }

        return clone;
    }
}
