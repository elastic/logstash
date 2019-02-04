package co.elastic.logstash.api;

import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map;

/**
 * Plugin configuration specification. Allows the name, type, deprecation status, required status, and default
 * value for each configuration setting to be defined.
 * @param <T> The expected type of the setting value.
 */
public final class PluginConfigSpec<T> {

    private final String name;

    private final Class<T> type;

    private final boolean deprecated;

    private final boolean required;

    private final T defaultValue;

    private String rawDefaultValue;

    private final Collection<PluginConfigSpec<?>> children;

    private PluginConfigSpec(final String name, final Class<T> type,
        final T defaultValue, final boolean deprecated, final boolean required) {
        this(name, type, defaultValue, deprecated, required, Collections.emptyList());
    }

    private PluginConfigSpec(final String name, final Class<T> type,
        final T defaultValue, final boolean deprecated, final boolean required,
        final Collection<PluginConfigSpec<?>> children) {
        this.name = name;
        this.type = type;
        this.defaultValue = defaultValue;
        this.deprecated = deprecated;
        this.required = required;
        if (!children.isEmpty() && !Map.class.isAssignableFrom(type)) {
            throw new IllegalArgumentException("Only map type settings can have defined children.");
        }
        this.children = children;
    }

    public static PluginConfigSpec<String> stringSetting(final String name) {
        return new PluginConfigSpec<>(
            name, String.class, null, false, false
        );
    }

    public static PluginConfigSpec<String> stringSetting(final String name, final String defaultValue) {
        return new PluginConfigSpec<>(
                name, String.class, defaultValue, false, false
        );
    }

    public static PluginConfigSpec<String> requiredStringSetting(final String name) {
        return new PluginConfigSpec<>(name, String.class, null, false, true);
    }

    public static PluginConfigSpec<String> stringSetting(final String name, final String defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(name, String.class, defaultValue, deprecated, required);
    }

    public static PluginConfigSpec<Codec> codecSetting(final String name) {
        return new PluginConfigSpec<>(
                name, Codec.class, null, false, false
        );
    }

    public static PluginConfigSpec<Codec> codecSetting(final String name, final String defaultCodecName) {
        PluginConfigSpec<Codec> pcs = new PluginConfigSpec<>(
                name, Codec.class, null, false, false
        );
        pcs.rawDefaultValue = defaultCodecName;
        return pcs;
    }

    public static PluginConfigSpec<Codec> codecSetting(final String name, final Codec defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(name, Codec.class, defaultValue, deprecated, required);
    }

    public static PluginConfigSpec<Long> numSetting(final String name) {
        return new PluginConfigSpec<>(
            name, Long.class, null, false, false
        );
    }

    public static PluginConfigSpec<Long> numSetting(final String name, final long defaultValue) {
        return new PluginConfigSpec<>(
            name, Long.class, defaultValue, false, false
        );
    }

    public static PluginConfigSpec<Long> numSetting(final String name, final long defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(name, Long.class, defaultValue, deprecated, required);
    }

    public static PluginConfigSpec<Boolean> booleanSetting(final String name) {
        return new PluginConfigSpec<>(name, Boolean.class, null, false, false);
    }

    public static PluginConfigSpec<Boolean> booleanSetting(final String name, final boolean defaultValue) {
        return new PluginConfigSpec<>(name, Boolean.class, defaultValue, false, false);
    }

    public static PluginConfigSpec<Boolean> requiredBooleanSetting(final String name) {
        return new PluginConfigSpec<>(name, Boolean.class, null, false, true);
    }

    public static PluginConfigSpec<Boolean> booleanSetting(final String name, final boolean defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec<>(name, Boolean.class, defaultValue, deprecated, required);
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<Map<String, Object>> hashSetting(final String name) {
        return new PluginConfigSpec(name, Map.class, null, false, false);
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<Map<String, Object>> hashSetting(final String name, Map<String, Object> defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec(name, Map.class, defaultValue, deprecated, required);
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<List<Object>> arraySetting(final String name) {
        return new PluginConfigSpec(name, List.class, null, false, false);
    }

    @SuppressWarnings({"unchecked","rawtypes"})
    public static PluginConfigSpec<List<Object>> arraySetting(final String name, List<Object> defaultValue, boolean deprecated, boolean required) {
        return new PluginConfigSpec(name, List.class, defaultValue, deprecated, required);
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

    public String getRawDefaultValue() {
        return rawDefaultValue;
    }
}
