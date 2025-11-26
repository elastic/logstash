package org.logstash.env2yaml;

import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.PosixFilePermission;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Set;
import java.util.TreeMap;
import org.snakeyaml.engine.v2.api.Dump;
import org.snakeyaml.engine.v2.api.DumpSettings;
import org.snakeyaml.engine.v2.api.Load;
import org.snakeyaml.engine.v2.api.LoadSettings;
import org.snakeyaml.engine.v2.common.FlowStyle;
import org.snakeyaml.engine.v2.common.ScalarStyle;

/**
 * Environment variable to YAML configuration merger
 *
 * Takes environment variables and merges them into logstash.yml
 * Example: docker run -e pipeline.workers=6
 * or: docker run -e PIPELINE_WORKERS=6
 * Result: pipeline.workers: 6 in logstash.yml
 */
public class Env2Yaml {
    private static final DateTimeFormatter TIMESTAMP_FORMAT = DateTimeFormatter.ofPattern("yyyy/MM/dd HH:mm:ss");
    private static class SettingValidator {
        private final Map<String, String> normalizedToCanonical;

        public SettingValidator() {
            this.normalizedToCanonical = buildSettingMap();
        }

        private Map<String, String> buildSettingMap() {
            Map<String, String> map = new TreeMap<>();
            String[] allowedConfigs = {
                "api.enabled", "api.http.host", "api.http.port", "api.environment",
                "node.name", "path.data", "pipeline.id", "pipeline.workers",
                "pipeline.output.workers", "pipeline.batch.size", "pipeline.batch.delay",
                "pipeline.unsafe_shutdown", "pipeline.ecs_compatibility", "pipeline.ordered",
                "pipeline.plugin_classloaders", "pipeline.separate_logs", "path.config",
                "config.string", "config.test_and_exit", "config.reload.automatic",
                "config.reload.interval", "config.debug", "config.support_escapes",
                "config.field_reference.escape_style", "queue.type", "path.queue",
                "queue.page_capacity", "queue.max_events", "queue.max_bytes",
                "queue.checkpoint.acks", "queue.checkpoint.writes", "queue.checkpoint.interval",
                "queue.compression", "queue.drain", "dead_letter_queue.enable",
                "dead_letter_queue.max_bytes", "dead_letter_queue.flush_interval",
                "dead_letter_queue.storage_policy", "dead_letter_queue.retain.age",
                "path.dead_letter_queue", "log.level", "log.format",
                "log.format.json.fix_duplicate_message_fields", "metric.collect",
                "path.logs", "path.plugins", "api.auth.type", "api.auth.basic.username",
                "api.auth.basic.password", "api.auth.basic.password_policy.mode",
                "api.auth.basic.password_policy.length.minimum", "api.auth.basic.password_policy.include.upper",
                "api.auth.basic.password_policy.include.lower", "api.auth.basic.password_policy.include.digit",
                "api.auth.basic.password_policy.include.symbol", "allow_superuser",
                "monitoring.cluster_uuid", "xpack.monitoring.allow_legacy_collection",
                "xpack.monitoring.enabled", "xpack.monitoring.collection.interval",
                "xpack.monitoring.elasticsearch.hosts", "xpack.monitoring.elasticsearch.username",
                "xpack.monitoring.elasticsearch.password", "xpack.monitoring.elasticsearch.proxy",
                "xpack.monitoring.elasticsearch.api_key", "xpack.monitoring.elasticsearch.cloud_auth",
                "xpack.monitoring.elasticsearch.cloud_id", "xpack.monitoring.elasticsearch.sniffing",
                "xpack.monitoring.elasticsearch.ssl.certificate_authority", "xpack.monitoring.elasticsearch.ssl.ca_trusted_fingerprint",
                "xpack.monitoring.elasticsearch.ssl.verification_mode", "xpack.monitoring.elasticsearch.ssl.truststore.path",
                "xpack.monitoring.elasticsearch.ssl.truststore.password", "xpack.monitoring.elasticsearch.ssl.keystore.path",
                "xpack.monitoring.elasticsearch.ssl.keystore.password", "xpack.monitoring.elasticsearch.ssl.certificate",
                "xpack.monitoring.elasticsearch.ssl.key", "xpack.monitoring.elasticsearch.ssl.cipher_suites",
                "xpack.management.enabled", "xpack.management.logstash.poll_interval",
                "xpack.management.pipeline.id", "xpack.management.elasticsearch.hosts",
                "xpack.management.elasticsearch.username", "xpack.management.elasticsearch.password",
                "xpack.management.elasticsearch.proxy", "xpack.management.elasticsearch.api_key",
                "xpack.management.elasticsearch.cloud_auth", "xpack.management.elasticsearch.cloud_id",
                "xpack.management.elasticsearch.sniffing", "xpack.management.elasticsearch.ssl.certificate_authority",
                "xpack.management.elasticsearch.ssl.ca_trusted_fingerprint", "xpack.management.elasticsearch.ssl.verification_mode",
                "xpack.management.elasticsearch.ssl.truststore.path", "xpack.management.elasticsearch.ssl.truststore.password",
                "xpack.management.elasticsearch.ssl.keystore.path", "xpack.management.elasticsearch.ssl.keystore.password",
                "xpack.management.elasticsearch.ssl.certificate", "xpack.management.elasticsearch.ssl.key",
                "xpack.management.elasticsearch.ssl.cipher_suites", "xpack.geoip.download.endpoint",
                "xpack.geoip.downloader.enabled"
            };

            for (String configName : allowedConfigs) {
                String normalizedKey = normalizeKey(configName);
                map.put(normalizedKey, configName);
            }
            return map;
        }

        public String findCanonicalSetting(String envVarName) {
            String normalized = normalizeKey(envVarName);
            return normalizedToCanonical.get(normalized);
        }
    }

    private static String normalizeKey(String key) {
        return key.toLowerCase()
                 .replace(".", "")
                 .replace("_", "");
    }

    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("usage: env2yaml FILENAME");
            System.exit(1);
        }

        try {
            String configPath = args[0];
            new Env2Yaml().processConfigFile(configPath);
        } catch (Exception e) {
            System.err.println("error: " + e.getMessage());
            System.exit(1);
        }
    }

    private void processConfigFile(String configPath) throws Exception {
        Path fileLocation = Paths.get(configPath);
        Map<String, Object> configData = loadExistingConfig(fileLocation);

        SettingValidator validator = new SettingValidator();
        boolean addedNewConfigs = incorporateEnvironmentVars(configData, validator);

        if (addedNewConfigs) {
            saveUpdatedConfig(fileLocation, configData);
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> loadExistingConfig(Path fileLocation) throws Exception {
        if (!Files.exists(fileLocation)) {
            return new TreeMap<>();
        }
        LoadSettings loadSettings = LoadSettings.builder().build();
        Load loader = new Load(loadSettings);
        try (InputStream fileInput = Files.newInputStream(fileLocation)) {
            Object parsedData = loader.loadFromInputStream(fileInput);
            if (parsedData instanceof Map) {
                // Convert to TreeMap to ensure alphabetical ordering like Go version
                return new TreeMap<>((Map<String, Object>) parsedData);
            }
            return new TreeMap<>();
        }
    }

    private boolean incorporateEnvironmentVars(Map<String, Object> configData, SettingValidator validator) {
        boolean addedNewConfigs = false;

        for (Map.Entry<String, String> envEntry : System.getenv().entrySet()) {
            String envVarName = envEntry.getKey();
            String envValue = envEntry.getValue();
            String canonicalSetting = validator.findCanonicalSetting(envVarName);

            if (canonicalSetting != null) {
                addedNewConfigs = true;
                System.err.println(LocalDateTime.now().format(TIMESTAMP_FORMAT) + " Setting '" + canonicalSetting + "' from environment.");
                configData.put(canonicalSetting, "${" + envVarName + "}");
            }
        }

        return addedNewConfigs;
    }

    private void saveUpdatedConfig(Path fileLocation, Map<String, Object> configData) throws Exception {
        // Configure YAML output to match Go version formatting (block style)
        DumpSettings dumpSettings = DumpSettings.builder()
            .setDefaultFlowStyle(FlowStyle.BLOCK)
            .setDefaultScalarStyle(ScalarStyle.PLAIN)
            .setIndent(2)
            .build();
        Dump dumper = new Dump(dumpSettings);
        String yamlOutput = dumper.dumpToString(configData);

        Set<PosixFilePermission> existingPermissions = getFilePermissions(fileLocation);

        Files.write(fileLocation, yamlOutput.getBytes(StandardCharsets.UTF_8), StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING);

        applyFilePermissions(fileLocation, existingPermissions);
    }

    private Set<PosixFilePermission> getFilePermissions(Path fileLocation) {
        try {
            return Files.getPosixFilePermissions(fileLocation);
        } catch (UnsupportedOperationException e) {
            return null;
        } catch (Exception e) {
            return null;
        }
    }

    private void applyFilePermissions(Path fileLocation, Set<PosixFilePermission> existingPermissions) {
        if (existingPermissions != null) {
            try {
                Files.setPosixFilePermissions(fileLocation, existingPermissions);
            } catch (Exception e) {
                // Ignore failures
            }
        }
    }
}
