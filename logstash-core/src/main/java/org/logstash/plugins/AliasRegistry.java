package org.logstash.plugins;

import org.logstash.plugins.PluginLookup.PluginType;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;

public class AliasRegistry {

    private final static class PluginCoordinate {
        private final PluginType type;
        private final String name;

        public PluginCoordinate(PluginType type, String name) {
            this.type = type;
            this.name = name;
        }

        @Override
        public boolean equals(Object o) {
            if (this == o) return true;
            if (o == null || getClass() != o.getClass()) return false;
            PluginCoordinate that = (PluginCoordinate) o;
            return type == that.type && Objects.equals(name, that.name);
        }

        @Override
        public int hashCode() {
            return Objects.hash(type, name);
        }

        PluginCoordinate withName(String name) {
            return new PluginCoordinate(this.type, name);
        }
    }


    private final Map<PluginCoordinate, String> aliases = new HashMap<>();
    private final Map<PluginCoordinate, String> reversedAliases = new HashMap<>();

    public AliasRegistry() {
        Map<PluginCoordinate, String> defaultDefinitions = new HashMap<>();
        defaultDefinitions.put(new PluginCoordinate(PluginType.INPUT, "elastic_agent"), "beats");
        configurePluginAliases(defaultDefinitions);
    }

    /**
     * Constructor used in tests to customize the plugins renames.
     * The input map's key are tuples of (type, name)
     * */
    public AliasRegistry(Map<List<String>, String> aliasDefinitions) {
        Map<PluginCoordinate, String> aliases = new HashMap<>();

        // transform the (tye, name) into PluginCoordinate
        for (Map.Entry<List<String>, String> e : aliasDefinitions.entrySet()) {
            final List<String> tuple = e.getKey();
            final PluginCoordinate key = mapTupleToCoordinate(tuple);
            aliases.put(key, e.getValue());
        }

        configurePluginAliases(aliases);
    }

    private PluginCoordinate mapTupleToCoordinate(List<String> tuple) {
        if (tuple.size() != 2) {
            throw new IllegalArgumentException("Expected a tuple of 2 elements, but found: " + tuple);
        }
        final PluginType type = PluginType.valueOf(tuple.get(0).toUpperCase());
        final String name = tuple.get(1);
        final PluginCoordinate key = new PluginCoordinate(type, name);
        return key;
    }

    private void configurePluginAliases(Map<PluginCoordinate, String> aliases) {
        this.aliases.putAll(aliases);
        for (Map.Entry<PluginCoordinate, String> e : this.aliases.entrySet()) {
            final PluginCoordinate reversedAlias = e.getKey().withName(e.getValue());
            if (reversedAliases.containsKey(reversedAlias)) {
                throw new IllegalStateException("Found plugin " + e.getValue() + " aliased more than one time");
            }
            reversedAliases.put(reversedAlias, e.getKey().name);
        }
    }

    public boolean isAlias(String type, String pluginName) {
        final PluginType pluginType = PluginType.valueOf(type.toUpperCase());

        return isAlias(pluginType, pluginName);
    }

    public boolean isAlias(PluginType type, String pluginName) {
        return aliases.containsKey(new PluginCoordinate(type, pluginName));
    }

    public String originalFromAlias(PluginType type, String alias) {
        return aliases.get(new PluginCoordinate(type, alias));
    }

    public String originalFromAlias(String type, String alias) {
        return originalFromAlias(PluginType.valueOf(type.toUpperCase()), alias);
    }

    public Optional<String> aliasFromOriginal(PluginType type, String realPluginName) {
        return Optional.ofNullable(reversedAliases.get(new PluginCoordinate(type, realPluginName)));
    }

    /**
     * if pluginName is an alias then return the real plugin name else return it unchanged
     */
    public String resolveAlias(String type, String pluginName) {
        final PluginCoordinate pluginCoord = new PluginCoordinate(PluginType.valueOf(type.toUpperCase()), pluginName);
        return aliases.getOrDefault(pluginCoord, pluginName);
    }
}
