package org.logstash.plugins;

import org.junit.Test;
import org.logstash.plugins.PluginLookup.PluginType;

import java.io.IOException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.*;

import static org.junit.Assert.*;

public class AliasRegistryTest {

    @Test
    public void testLoadAliasesFromYAML() {
        final AliasRegistry sut = new AliasRegistry();

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

    @Test
    @SuppressWarnings("rawtypes")
    public void testConcurrentCreationOfAliasRegistries() throws ExecutionException, InterruptedException, TimeoutException {
        int cpus = Runtime.getRuntime().availableProcessors();
        ExecutorService pool = Executors.newFixedThreadPool(4);

        List<Throwable> errors = new ArrayList<>();
        List<Future> taskResults = new ArrayList<>(cpus * 1024 * 10);

        Runnable task = createTestTask(errors);
        for (int i = 0; i < cpus * 1024 * 10; i++) {
            Future<?> taskFuture = pool.submit(task);
            taskResults.add(taskFuture);
        }


        for (Future taskResult: taskResults) {
            taskResult.get(1_000, TimeUnit.SECONDS);
        }

        pool.shutdown();

        assertTrue("No errors were raised", errors.isEmpty());
    }

    private Runnable createTestTask(List<Throwable> errors) {
        return () -> {
            try {
                AliasRegistry aliasRegistry = new AliasRegistry();
                assertEquals("aliased_input1 should be the alias for beats input",
                        "beats", aliasRegistry.originalFromAlias(PluginType.INPUT, "aliased_input1"));
            } catch (Throwable th) {
                errors.add(th);
            }
        };
    }


    @Test
    public void testConcurrentCreationOfAliasRegistriesSpinning() throws InterruptedException {
        List<Throwable> errors = new ArrayList<>();
        Runnable task = new Runnable() {
            @Override
            public void run() {
                long start = System.currentTimeMillis();
                while (System.currentTimeMillis() - start <= 5_000 && !Thread.currentThread().isInterrupted()) {
                    try {
                        AliasRegistry aliasRegistry = new AliasRegistry();
                        assertEquals("aliased_input1 should be the alias for beats input",
                                "beats", aliasRegistry.originalFromAlias(PluginType.INPUT, "aliased_input1"));
                    } catch (Throwable th) {
                        errors.add(th);
                    }
                }
            }
        };


        Thread th1 = new Thread(task);
        Thread th2 = new Thread(task);

        th1.start();
        th2.start();

        th1.join();
        th2.join();

        assertTrue("No errors were raised", errors.isEmpty());
    }
}