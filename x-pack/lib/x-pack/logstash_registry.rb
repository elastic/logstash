# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.
#
require "logstash/plugins/registry"
require "logstash/modules/util"
require "monitoring/monitoring"
require "monitoring/inputs/metrics"
require "config_management/extension"
require "modules/xpack_scaffold"

LogStash::PLUGIN_REGISTRY.add(:input, "metrics", LogStash::Inputs::Metrics)
LogStash::PLUGIN_REGISTRY.add(:universal, "monitoring", LogStash::MonitoringExtension)
LogStash::PLUGIN_REGISTRY.add(:universal, "config_management", LogStash::ConfigManagement::Extension)
LogStash::PLUGIN_REGISTRY.add(:modules, "arcsight",
                              LogStash::Modules::XpackScaffold.new("arcsight",
                                                                   File.join(File.dirname(__FILE__), "..", "..", "modules", "arcsight", "configuration"),
                                                                   ["basic", "trial", "standard", "gold", "platinum"]
                              ))
