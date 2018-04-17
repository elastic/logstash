package org.logstash.execution.plugins;

import java.util.Collection;
import java.util.Collections;
import java.util.Map;
import java.util.Objects;

public final class PluginConfigSpec<T> {

    private final String name;

    private final Class<T> type;

    private final ConfigValueConverter<T> valueConverter;

    private final boolean deprecated;

    private final boolean required;

    private final T defaultValue;

    private final Collection<PluginConfigSpec<?>> children;

    public PluginConfigSpec(final String name, final Class<T> type,
                            final T defaultValue, final ConfigValueConverter<T> configValueConverter,
                            final boolean deprecated, final boolean required) {
        this(name, type, defaultValue, configValueConverter, deprecated, required, Collections.emptyList());
    }

    public PluginConfigSpec(final String name, final Class<T> type, final T defaultValue,
                            final ConfigValueConverter<T> configValueConverter, final boolean deprecated,
                            final boolean required, final Collection<PluginConfigSpec<?>> children) {
        this.name = name;
        this.type = type;
        this.valueConverter = configValueConverter;
        this.defaultValue = defaultValue;
        this.deprecated = deprecated;
        this.required = required;
        if (!children.isEmpty() && !Map.class.isAssignableFrom(type)) {
            throw new IllegalArgumentException("Only map type settings can have defined children.");
        }
        this.children = children;
    }

    public Collection<PluginConfigSpec<?>> children() {
        return children;
    }

    public boolean deprecated() {
        return this.deprecated;
    }

    public boolean required() {
        return this.required;
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

    public T getValue(String raw) {
        return raw == null
                ? defaultValue()
                : valueConverter.convertValue(raw);
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || !(o instanceof PluginConfigSpec)) {
            return false;
        }

        PluginConfigSpec p = (PluginConfigSpec)o;
        return Objects.equals(name, p.name);
    }

}
