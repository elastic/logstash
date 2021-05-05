// env2yaml
//
// Merge environment variables into logstash.yml.
// For example, running Docker with:
//
//   docker run -e pipeline.workers=6
//
// or
//
//   docker run -e PIPELINE_WORKERS=6
//
// will cause logstash.yml to contain the line:
//
//   pipeline.workers: 6
//
package main

import (
	"errors"
	"gopkg.in/yaml.v2"
	"io/ioutil"
	"log"
	"os"
	"strings"
)

// If the given string can be parsed as YAML, then do so and return the
// resulting entity. Otherwise, return the string unmodified.
func FromYamlIfPossible(str string) interface{} {
	var entity interface{}
	err := yaml.Unmarshal([]byte(str), &entity)
	if err == nil {
		return entity
	} else {
		return str
	}
}

// Given a setting name, return a downcased version with delimiters removed.
func squashSetting(setting string) string {
	downcased := strings.ToLower(setting)
	de_dotted := strings.Replace(downcased, ".", "", -1)
	de_underscored := strings.Replace(de_dotted, "_", "", -1)
	return de_underscored
}

// Given a setting name like "pipeline.workers" or "PIPELINE_UNSAFE_SHUTDOWN",
// return the canonical setting name. eg. 'pipeline.unsafe_shutdown'
func normalizeSetting(setting string) (string, error) {
	valid_settings := []string{
		"node.name",
		"path.data",
		"pipeline.id",
		"pipeline.workers",
		"pipeline.output.workers",
		"pipeline.batch.size",
		"pipeline.batch.delay",
		"pipeline.unsafe_shutdown",
		"pipeline.ecs_compatibility",
		"pipeline.plugin_classloaders",
		"path.config",
		"config.string",
		"config.test_and_exit",
		"config.reload.automatic",
		"config.reload.interval",
		"config.debug",
		"config.support_escapes",
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
		"path.dead_letter_queue",
		"http.host",
		"http.port",
		"log.level",
		"log.format",
		"modules",
		"path.logs",
		"path.plugins",
		"xpack.monitoring.enabled",
		"xpack.monitoring.collection.interval",
		"xpack.monitoring.elasticsearch.hosts",
		"xpack.monitoring.elasticsearch.username",
		"xpack.monitoring.elasticsearch.password",
		"xpack.monitoring.elasticsearch.proxy",
		"xpack.monitoring.elasticsearch.ssl.certificate_authority",
		"xpack.monitoring.elasticsearch.ssl.verification_mode",
		"xpack.monitoring.elasticsearch.ssl.truststore.path",
		"xpack.monitoring.elasticsearch.ssl.truststore.password",
		"xpack.monitoring.elasticsearch.ssl.keystore.path",
		"xpack.monitoring.elasticsearch.ssl.keystore.password",
		"xpack.management.enabled",
		"xpack.management.logstash.poll_interval",
		"xpack.management.pipeline.id",
		"xpack.management.elasticsearch.hosts",
		"xpack.management.elasticsearch.username",
		"xpack.management.elasticsearch.password",
		"xpack.management.elasticsearch.proxy",
		"xpack.management.elasticsearch.ssl.certificate_authority",
		"xpack.management.elasticsearch.ssl.verification_mode",
		"xpack.management.elasticsearch.ssl.truststore.path",
		"xpack.management.elasticsearch.ssl.truststore.password",
		"xpack.management.elasticsearch.ssl.keystore.path",
		"xpack.management.elasticsearch.ssl.keystore.password",
		"cloud.id",
		"cloud.auth",
	}

	for _, valid_setting := range valid_settings {
		if squashSetting(setting) == squashSetting(valid_setting) {
			return valid_setting, nil
		}
	}
	return "", errors.New("Invalid setting: " + setting)
}

func main() {
	if len(os.Args) != 2 {
		log.Fatalf("usage: env2yaml FILENAME")
	}
	settingsFilePath := os.Args[1]

	settingsFile, err := ioutil.ReadFile(settingsFilePath)
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	// Read the original settings file into a map.
	settings := make(map[string]interface{})
	err = yaml.Unmarshal(settingsFile, &settings)
	if err != nil {
		log.Fatalf("error: %v", err)
	}

	// Merge any valid settings found in the environment.
	foundNewSettings := false
	for _, line := range os.Environ() {
		kv := strings.SplitN(line, "=", 2)
		key := kv[0]
		value := kv[1]
		setting, err := normalizeSetting(key)
		if err == nil {
			foundNewSettings = true
			log.Printf("Setting '%s' from environment.", setting)
			settings[setting] = FromYamlIfPossible(value)
		}
	}

	if foundNewSettings {
		output, err := yaml.Marshal(&settings)
		if err != nil {
			log.Fatalf("error: %v", err)
		}

		stat, err := os.Stat(settingsFilePath)
		if err != nil {
			log.Fatalf("error: %v", err)
		}

		err = ioutil.WriteFile(settingsFilePath, output, stat.Mode())
		if err != nil {
			log.Fatalf("error: %v", err)
		}
	}
}
