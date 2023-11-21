package org.logstash.plugins;

import org.apache.commons.codec.digest.DigestUtils;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.plugins.PluginLookup.PluginType;
import org.logstash.plugins.aliases.AliasDocumentReplace;
import org.logstash.plugins.aliases.AliasPlugin;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.Scanner;
import java.util.stream.Collectors;

import org.yaml.snakeyaml.Yaml;

public class AliasRegistry {

    private static final Logger LOGGER = LogManager.getLogger(AliasRegistry.class);

    final static class PluginCoordinate {
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

        @Override
        public String toString() {
            return "PluginCoordinate{type=" + type + ", name='" + name + "'}";
        }

        public String fullName() {
            return "logstash-" + type.rubyLabel().toString().toLowerCase() + "-" + name;
        }
    }

    private static class YamlWithChecksum {

        private static YamlWithChecksum load(InputStream in) {
            try (Scanner scanner = new Scanner(in, StandardCharsets.UTF_8.name())) {
                // read the header line
                final String header = scanner.nextLine();
                if (!header.startsWith("#CHECKSUM:")) {
                    throw new IllegalArgumentException("Bad header format, expected '#CHECKSUM: ...' but found " + header);
                }
                final String extractedHash = header.substring("#CHECKSUM:".length()).trim();

                // read the comment
                scanner.nextLine();

                // collect all remaining lines
                final StringBuilder yamlBuilder = new StringBuilder();
                scanner.useDelimiter("\\z"); // EOF
                if (scanner.hasNext()) {
                    yamlBuilder.append(scanner.next());
                }
                final String yamlContents = yamlBuilder.toString();
                return new YamlWithChecksum(yamlContents, extractedHash);
            }
        }

        final String yamlContents;
        final String checksumHash;

        private YamlWithChecksum(final String yamlContents, final String checksumHash) {
            this.yamlContents = yamlContents;
            this.checksumHash = checksumHash;
        }

        @SuppressWarnings("unchecked")
        private Map<PluginType, List<AliasPlugin>> decodeYaml() throws IOException {
            Yaml yaml = new Yaml();
            Map<String, Object> yamlMap = yaml.load(yamlContents);

            // Convert the loaded YAML content to the expected type structure
            return convertYamlMapToObject(yamlMap);
        }

        private String computeHashFromContent() {
            return DigestUtils.sha256Hex(yamlContents);
        }

        @SuppressWarnings("unchecked")
        private Map<PluginType, List<AliasPlugin>> convertYamlMapToObject(Map<String, Object> yamlMap) {
            Map<PluginType, List<AliasPlugin>> result = new HashMap<>();

            for (Map.Entry<String, Object> entry : yamlMap.entrySet()) {
                PluginType pluginType = PluginType.valueOf(entry.getKey().toUpperCase());
                List<Map<String, Object>> aliasList = (List<Map<String, Object>>) entry.getValue();

                List<AliasPlugin> aliasPlugins = aliasList.stream()
                        .map(YamlWithChecksum::convertToAliasPluginDefinition)
                        .collect(Collectors.toList());

                result.put(pluginType, aliasPlugins);
            }
            return result;
        }

        @SuppressWarnings("unchecked")
        private static AliasPlugin convertToAliasPluginDefinition(Map<String, Object> aliasEntry) {
            String aliasName = (String) aliasEntry.get("alias");
            String from = (String) aliasEntry.get("from");

            List<Map<String, String>> docs = (List<Map<String, String>>) aliasEntry.get("docs");
            List<AliasDocumentReplace> replaceRules = convertToDocumentationReplacementRules(docs);

            return new AliasPlugin(aliasName, from, replaceRules);
        }

        private static List<AliasDocumentReplace> convertToDocumentationReplacementRules(List<Map<String, String>> docs) {
            if (docs == null) {
                return Collections.emptyList();
            }
            return docs.stream()
                    .map(YamlWithChecksum::convertSingleDocReplacementRule)
                    .collect(Collectors.toList());
        }

        private static AliasDocumentReplace convertSingleDocReplacementRule(Map<String, String> doc) {
            String replace = doc.get("replace");
            String with = doc.get("with");
            return new AliasDocumentReplace(replace, with);
        }
    }

    static class AliasYamlLoader {

        Map<PluginCoordinate, String> loadAliasesDefinitions(Path yamlPath) {
            final FileInputStream in;
            try {
                in = new FileInputStream(yamlPath.toFile());
            } catch (FileNotFoundException e) {
                LOGGER.warn("Can't find aliases yml definition file in in path: " + yamlPath, e);
                return Collections.emptyMap();
            }

            return loadAliasesDefinitionsFromInputStream(in);
        }

        Map<PluginCoordinate, String> loadAliasesDefinitions() {
            final String filePath = "org/logstash/plugins/plugin_aliases.yml";
            InputStream in = null;
            try {
                URL url = AliasYamlLoader.class.getClassLoader().getResource(filePath);
                if (url != null) {
                    URLConnection connection = url.openConnection();
                    if (connection != null) {
                        connection.setUseCaches(false);
                        in = connection.getInputStream();
                    }
                }
            } catch (IOException e){
                LOGGER.warn("Unable to read alias definition in jar resources: {}", filePath, e);
                return Collections.emptyMap();
            }
            if (in == null) {
                LOGGER.warn("Malformed yaml file in yml definition file in jar resources: {}", filePath);
                return Collections.emptyMap();
            }

            return loadAliasesDefinitionsFromInputStream(in);
        }

        private Map<PluginCoordinate, String> loadAliasesDefinitionsFromInputStream(InputStream in) {
            final YamlWithChecksum aliasYml = YamlWithChecksum.load(in);
            final String calculatedHash = aliasYml.computeHashFromContent();
            if (!calculatedHash.equals(aliasYml.checksumHash)) {
                LOGGER.warn("Bad checksum value, expected {} but found {}", calculatedHash, aliasYml.checksumHash);
                return Collections.emptyMap();
            }

            // decode yaml to Map<PluginType, List<AliasPlugin>> structure
            final Map<PluginType, List<AliasPlugin>> aliasedDescriptions;
            try {
                aliasedDescriptions = aliasYml.decodeYaml();
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

        private Map<PluginCoordinate, String> extractDefinitions(PluginType pluginType,
                                                                 Map<PluginType, List<AliasPlugin>> aliasesYamlDefinitions) {
            final List<AliasPlugin> aliasedPlugins = aliasesYamlDefinitions.get(pluginType);
            if (Objects.isNull(aliasedPlugins)) {
                return Collections.emptyMap();
            }

            Map<PluginCoordinate, String> defaultDefinitions = new HashMap<>();
            aliasedPlugins.forEach(aliasPlugin -> {
                defaultDefinitions.put(new PluginCoordinate(pluginType, aliasPlugin.getAliasName()), aliasPlugin.getFrom());
            });
            return defaultDefinitions;
        }
    }


    private final Map<PluginCoordinate, String> aliases = new HashMap<>();
    private final Map<PluginCoordinate, String> reversedAliases = new HashMap<>();

    private static final AliasRegistry INSTANCE = new AliasRegistry();
    public static AliasRegistry getInstance() {
        return INSTANCE;
    }

    // The Default implementation of AliasRegistry.
    // This needs to be a singleton as multiple threads accessing may cause the first thread to close the jar file
    // leading to issues with subsequent threads loading the yaml file.
    private AliasRegistry() {
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
