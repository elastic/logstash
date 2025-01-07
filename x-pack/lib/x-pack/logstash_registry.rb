# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/runner" # needed for LogStash::XPACK_PATH
require "logstash/plugins/registry"
require "monitoring/monitoring"
require "monitoring/inputs/metrics"
require "monitoring/outputs/elasticsearch_monitoring"
require "config_management/extension"
require "geoip_database_management/extension"

LogStash::PLUGIN_REGISTRY.add(:input, "metrics", LogStash::Inputs::Metrics)
LogStash::PLUGIN_REGISTRY.add(:output, "elasticsearch_monitoring", LogStash::Outputs::ElasticSearchMonitoring)
LogStash::PLUGIN_REGISTRY.add(:universal, "monitoring", LogStash::MonitoringExtension)
LogStash::PLUGIN_REGISTRY.add(:universal, "config_management", LogStash::ConfigManagement::Extension)
LogStash::PLUGIN_REGISTRY.add(:universal, "geoip_database_management", LogStash::GeoipDatabaseManagement::Extension)

license_levels = Hash.new
license_levels.default = LogStash::LicenseChecker::LICENSE_TYPES