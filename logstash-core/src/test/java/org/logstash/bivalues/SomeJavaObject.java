package org.logstash.bivalues;

public class SomeJavaObject<T> {
    private T value;

    public T getValue() {
        return value;
    }

    public SomeJavaObject(T value) {
        this.value = value;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof SomeJavaObject)) return false;

        SomeJavaObject<?> that = (SomeJavaObject<?>) o;

        return value != null ? value.equals(that.getValue()) : that.value == null;

    }

    @Override
    public int hashCode() {
        return value != null ? value.hashCode() : 0;
    }
}
