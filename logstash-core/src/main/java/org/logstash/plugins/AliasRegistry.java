package org.logstash.plugins;

import java.util.HashMap;
import java.util.Map;

public class AliasRegistry {
    private final Map<String, String> aliases = new HashMap<>();
    private final Map<String, String> reversedAliases = new HashMap<>();

    public AliasRegistry() {
        Map<String, String> defaultDefinitions = new HashMap<>();
        defaultDefinitions.put("elastic_agent", "beats");
        configurePluginAliases(defaultDefinitions);
    }

    /**
     * Constructor used in tests to customize the plugins renames
     * */
    public AliasRegistry(Map<String, String> aliasDefinitions) {
        configurePluginAliases(aliasDefinitions);
    }

    private void configurePluginAliases(Map<String, String> aliases) {
        this.aliases.putAll(aliases);
        for (Map.Entry<String, String> e : this.aliases.entrySet()) {
            if (reversedAliases.containsKey(e.getValue())) {
                throw new IllegalStateException("Found plugin " + e.getValue() + " aliased more than one time");
            }
            reversedAliases.put(e.getValue(), e.getKey());
        }
    }

    public boolean isAlias(String pluginName) {
        return aliases.containsKey(pluginName);
    }

    public boolean isAliased(String realPluginName) {
        return aliases.containsValue(realPluginName);
    }

    public String originalFromAlias(String pluginAlias) {
        return aliases.get(pluginAlias);
    }

    public String aliasFromOriginal(String realPluginName) {
        return reversedAliases.get(realPluginName);
    }

    /**
     * if pluginName is an alias then return the real plugin name else return it unchanged
     */
    public String resolveAlias(String pluginName) {
        return aliases.getOrDefault(pluginName, pluginName);
    }
}
