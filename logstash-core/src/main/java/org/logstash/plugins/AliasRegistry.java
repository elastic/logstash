package org.logstash.plugins;

import java.util.HashMap;
import java.util.Map;

public class AliasRegistry {
    private final Map<String, String> ALIASES = new HashMap<>();
    private final Map<String, String> REVERSE_ALIASES = new HashMap<>();

    public AliasRegistry() {
        configurePluginAliases();
    }

    private void configurePluginAliases() {
        ALIASES.put("elastic_agent", "beats");
        ALIASES.put("dna_java_generator", "java_generator");
        for (Map.Entry<String, String> e : ALIASES.entrySet()) {
            if (REVERSE_ALIASES.containsKey(e.getValue())) {
                throw new IllegalStateException("Found plugin " + e.getValue() + " aliased more than one time");
            }
            REVERSE_ALIASES.put(e.getValue(), e.getKey());
        }
    }

    public boolean isAlias(String pluginName) {
        return ALIASES.containsKey(pluginName);
    }

    public boolean isAliased(String realPluginName) {
        return ALIASES.containsValue(realPluginName);
    }

    public String originalFromAlias(String pluginAlias) {
        return ALIASES.get(pluginAlias);
    }

    public String aliasFromOriginal(String realPluginName) {
        return REVERSE_ALIASES.get(realPluginName);
    }

    /**
     * if pluginName is an alias then return the real plugin name else return it unchanged
     */
    public String resolveAlias(String pluginName) {
        return ALIASES.getOrDefault(pluginName, pluginName);
    }
}
