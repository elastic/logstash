
require_relative "logstash/fips_validation"

LogStash::PLUGIN_REGISTRY.add(:universal, "fips_validation", LogStash::FipsValidation)
