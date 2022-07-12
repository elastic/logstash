package org.logstash.plugins;

import org.junit.Test;
import org.logstash.plugins.PluginLookup.PluginType;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;

import static org.junit.Assert.*;

public class AliasRegistryTest {

    @Test
    public void testLoadAliasesFromYAML() {
        final AliasRegistry sut = AliasRegistry.getInstance();

        assertEquals("aliased_input1 should be the alias for beats input",
                "beats", sut.originalFromAlias(PluginType.INPUT, "aliased_input1"));
        assertEquals("aliased_input2 should be the alias for tcp input",
                "tcp", sut.originalFromAlias(PluginType.INPUT, "aliased_input2"));
        assertEquals("aliased_filter should be the alias for json filter",
                "json", sut.originalFromAlias(PluginType.FILTER, "aliased_filter"));
    }

    @Test
    public void testProductionConfigAliasesGemsExists() throws IOException {
        final Path currentPath = Paths.get("./src/main/resources/org/logstash/plugins/plugin_aliases.yml").toAbsolutePath();
        final AliasRegistry.AliasYamlLoader aliasLoader = new AliasRegistry.AliasYamlLoader();
        final Map<AliasRegistry.PluginCoordinate, String> aliasesDefinitions = aliasLoader.loadAliasesDefinitions(currentPath);

        for (AliasRegistry.PluginCoordinate alias : aliasesDefinitions.keySet()) {
            final String gemName = alias.fullName();
            URL url = new URL("https://rubygems.org/api/v1/gems/" + gemName +".json");
            HttpURLConnection connection = (HttpURLConnection) url.openConnection();
            connection.setRequestMethod("GET");
            connection.setRequestProperty("Accept", "application/json");

            final String errorMsg = "Aliased plugin " + gemName + "specified in " + currentPath + " MUST be published on RubyGems";
            assertEquals(errorMsg, 200, connection.getResponseCode());
        }
    }
}