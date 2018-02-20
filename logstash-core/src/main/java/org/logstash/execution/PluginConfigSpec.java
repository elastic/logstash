package org.logstash.execution;

public final class PluginConfigSpec<T> {

    private final String name;

    private final Class<T> type;

    private final boolean deprecated;

    private final T defaultValue;

    public PluginConfigSpec(final String name, final Class<T> type,
        final T defaultValue, final boolean deprecated) {
        this.name = name;
        this.type = type;
        this.defaultValue = defaultValue;
        this.deprecated = deprecated;
    }

    public boolean deprecated() {
        return this.deprecated;
    }

    public T defaultValue() {
        return this.defaultValue;
    }

    public String name() {
        return name;
    }

    public Class<T> type() {
        return type;
    }

}
