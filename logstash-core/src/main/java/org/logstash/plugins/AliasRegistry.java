package org.logstash.plugins;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.dataformat.yaml.YAMLFactory;
import org.apache.commons.codec.digest.DigestUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.plugins.PluginLookup.PluginType;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Scanner;

public class AliasRegistry {

    private static final Logger LOGGER = LogManager.getLogger(AliasRegistry.class);

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

    private static class AliasYamlLoader {

        private String extractedHash;
        private String yaml;

        @SuppressWarnings("unchecked")
        private Map<PluginCoordinate, String> loadAliasesDefinitions() {
            try {
                parseYamlFile("org/logstash/plugins/plugin_aliases.yml");
            } catch (IllegalArgumentException badSyntaxExcp) {
                LOGGER.warn("Malformed yaml file", badSyntaxExcp);
                return Collections.emptyMap();
            }

            // calculate the hash-256
            final String sha256Hex = DigestUtils.sha256Hex(yaml);
            if (!sha256Hex.equals(extractedHash)) {
                LOGGER.warn("Bad checksum value, expected {} but found {}", sha256Hex, extractedHash);
                return Collections.emptyMap();
            }

            // decode yaml to nested maps
            final Map<String, Map<String, String>> aliasedDescriptions;
            try {
                ObjectMapper mapper = new ObjectMapper(new YAMLFactory());
                aliasedDescriptions = mapper.readValue(yaml, Map.class);
            } catch (IOException ioex) {
                LOGGER.error("Error decoding the yaml aliases file", ioex);
                return Collections.emptyMap();
            }

            // convert aliases nested maps definitions to plugin alias definitions
            final Map<PluginCoordinate, String> defaultDefinitions = new HashMap<>();
            defaultDefinitions.putAll(extractDefinitions(PluginType.INPUT, aliasedDescriptions));
            defaultDefinitions.putAll(extractDefinitions(PluginType.CODEC, aliasedDescriptions));
            defaultDefinitions.putAll(extractDefinitions(PluginType.FILTER, aliasedDescriptions));
            defaultDefinitions.putAll(extractDefinitions(PluginType.OUTPUT, aliasedDescriptions));
            return defaultDefinitions;
        }

        private void parseYamlFile(String yamlResourcePath) {
            final InputStream in = this.getClass().getClassLoader().getResourceAsStream(yamlResourcePath);

            try (Scanner scanner = new Scanner(in, StandardCharsets.UTF_8.name())) {
                // read the header line
                final String header = scanner.nextLine();
                if (!header.startsWith("#CHECKSUM:")) {
                    throw new IllegalArgumentException("Bad header format, expected '#CHECKSUM: ...' but found " + header);
                }
                extractedHash = header.substring("#CHECKSUM:".length()).trim();

                // read the comment
                scanner.nextLine();

                // collect all remaining lines
                final StringBuilder yamlBuilder = new StringBuilder();
                scanner.useDelimiter("\\z"); // EOF
                if (scanner.hasNext()) {
                    yamlBuilder.append(scanner.next());
                }
                yaml = yamlBuilder.toString();
            }
        }

        private Map<PluginCoordinate, String> extractDefinitions(PluginType pluginType,
                                                                 Map<String, Map<String, String>> aliasesYamlDefinitions) {
            Map<PluginCoordinate, String> defaultDefinitions = new HashMap<>();
            final Map<String, String> pluginDefinitions = aliasesYamlDefinitions.get(pluginType.name().toLowerCase());
            if (pluginDefinitions == null) {
                return Collections.emptyMap();
            }
            for (Map.Entry<String, String> aliasDef : pluginDefinitions.entrySet()) {
                defaultDefinitions.put(new PluginCoordinate(pluginType, aliasDef.getKey()), aliasDef.getValue());
            }
            return defaultDefinitions;
        }
    }


    private final Map<PluginCoordinate, String> aliases = new HashMap<>();
    private final Map<PluginCoordinate, String> reversedAliases = new HashMap<>();

    public AliasRegistry() {
        final AliasYamlLoader loader = new AliasYamlLoader();
        final Map<PluginCoordinate, String> defaultDefinitions = loader.loadAliasesDefinitions();
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
