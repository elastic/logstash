require 'yaml'

def squash_setting(setting)
  setting.downcase.gsub('.', '').gsub('_', '')
end

# Set filename
filename = ARGV[0]

# Load YAML file
settings = YAML.load_file(filename)

# Define list of valid settings
valid_settings = [
		"api.enabled",
		"api.http.host",
		"api.http.port",
		"api.environment",
		"node.name",
		"path.data",
		"pipeline.id",
		"pipeline.workers",
		"pipeline.output.workers",
		"pipeline.batch.size",
		"pipeline.batch.delay",
		"pipeline.unsafe_shutdown",
		"pipeline.ecs_compatibility",
		"pipeline.ordered",
		"pipeline.plugin_classloaders",
		"pipeline.separate_logs",
		"path.config",
		"config.string",
		"config.test_and_exit",
		"config.reload.automatic",
		"config.reload.interval",
		"config.debug",
		"config.support_escapes",
		"config.field_reference.escape_style",
		"event_api.tags.illegal",
		"queue.type",
		"path.queue",
		"queue.page_capacity",
		"queue.max_events",
		"queue.max_bytes",
		"queue.checkpoint.acks",
		"queue.checkpoint.writes",
		"queue.checkpoint.interval",
		"queue.drain",
		"dead_letter_queue.enable",
		"dead_letter_queue.max_bytes",
		"dead_letter_queue.flush_interval",
		"dead_letter_queue.storage_policy",
		"dead_letter_queue.retain.age",
		"path.dead_letter_queue",
		"http.enabled",     # DEPRECATED: prefer `api.enabled`
		"http.environment", # DEPRECATED: prefer `api.environment`
		"http.host",        # DEPRECATED: prefer `api.http.host`
		"http.port",        # DEPRECATED: prefer `api.http.port`
		"log.level",
		"log.format",
		"modules",
		"metric.collect",
		"path.logs",
		"path.plugins",
		"api.auth.type",
		"api.auth.basic.username",
		"api.auth.basic.password",
		"api.auth.basic.password_policy.mode",
		"api.auth.basic.password_policy.length.minimum",
		"api.auth.basic.password_policy.include.upper",
		"api.auth.basic.password_policy.include.lower",
		"api.auth.basic.password_policy.include.digit",
		"api.auth.basic.password_policy.include.symbol",
		"allow_superuser",
		"monitoring.cluster_uuid",
		"xpack.monitoring.enabled",
		"xpack.monitoring.collection.interval",
		"xpack.monitoring.elasticsearch.hosts",
		"xpack.monitoring.elasticsearch.username",
		"xpack.monitoring.elasticsearch.password",
		"xpack.monitoring.elasticsearch.proxy",
		"xpack.monitoring.elasticsearch.api_key",
		"xpack.monitoring.elasticsearch.cloud_auth",
		"xpack.monitoring.elasticsearch.cloud_id",
		"xpack.monitoring.elasticsearch.sniffing",
		"xpack.monitoring.elasticsearch.ssl.certificate_authority",
		"xpack.monitoring.elasticsearch.ssl.ca_trusted_fingerprint",
		"xpack.monitoring.elasticsearch.ssl.verification_mode",
		"xpack.monitoring.elasticsearch.ssl.truststore.path",
		"xpack.monitoring.elasticsearch.ssl.truststore.password",
		"xpack.monitoring.elasticsearch.ssl.keystore.path",
		"xpack.monitoring.elasticsearch.ssl.keystore.password",
		"xpack.monitoring.elasticsearch.ssl.certificate",
		"xpack.monitoring.elasticsearch.ssl.key",
		"xpack.monitoring.elasticsearch.ssl.cipher_suites",
		"xpack.management.enabled",
		"xpack.management.logstash.poll_interval",
		"xpack.management.pipeline.id",
		"xpack.management.elasticsearch.hosts",
		"xpack.management.elasticsearch.username",
		"xpack.management.elasticsearch.password",
		"xpack.management.elasticsearch.proxy",
		"xpack.management.elasticsearch.api_key",
		"xpack.management.elasticsearch.cloud_auth",
		"xpack.management.elasticsearch.cloud_id",
		"xpack.management.elasticsearch.sniffing",
		"xpack.management.elasticsearch.ssl.certificate_authority",
		"xpack.management.elasticsearch.ssl.ca_trusted_fingerprint",
		"xpack.management.elasticsearch.ssl.verification_mode",
		"xpack.management.elasticsearch.ssl.truststore.path",
		"xpack.management.elasticsearch.ssl.truststore.password",
		"xpack.management.elasticsearch.ssl.keystore.path",
		"xpack.management.elasticsearch.ssl.keystore.password",
		"xpack.management.elasticsearch.ssl.certificate",
		"xpack.management.elasticsearch.ssl.key",
		"xpack.management.elasticsearch.ssl.cipher_suites",
		"xpack.geoip.download.endpoint",
		"xpack.geoip.downloader.enabled",
		"cloud.id",
		"cloud.auth",
]

# Normalize keys in valid settings
normalized_valid_settings = valid_settings.map { |setting| squash_setting(setting) }

# Prepare a hash for mapping normalized keys back to their original form
valid_setting_map = Hash[normalized_valid_settings.zip(valid_settings)]

# Merge any valid settings found in the environment
found_new_settings = false

ENV.each do |key, value|
  normalized_key = squash_setting(key)

  # If the environment variable is a valid setting, update the settings
  if valid_setting_map[normalized_key]
    found_new_settings = true
    puts "Setting '#{valid_setting_map[normalized_key]}' from environment."

    # Try to parse the value as YAML
    begin
      parsed_value = YAML.load(value)
    rescue Psych::SyntaxError
      parsed_value = value
    end

    # Handle complex structures
    keys = valid_setting_map[normalized_key].split('.')
    last_key = keys.pop
    current = settings
    keys.each { |k| current = (current[k] ||= {}) }
    current[last_key] = parsed_value
  end
end

# If new settings were found, write them back to the YAML file
if found_new_settings
  File.open(filename, 'w') {|f| f.write settings.to_yaml } 
end

