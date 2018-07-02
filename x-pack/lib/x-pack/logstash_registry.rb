# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/runner" # needed for LogStash::XPACK_PATH
$LOAD_PATH << File.join(LogStash::XPACK_PATH, "modules", "azure", "lib")
require "logstash/plugins/registry"
require "logstash/modules/util"
require "monitoring/monitoring"
require "monitoring/inputs/metrics"
require "config_management/extension"
require "modules/xpack_scaffold"
require "filters/azure_event"

LogStash::PLUGIN_REGISTRY.add(:input, "metrics", LogStash::Inputs::Metrics)
LogStash::PLUGIN_REGISTRY.add(:universal, "monitoring", LogStash::MonitoringExtension)
LogStash::PLUGIN_REGISTRY.add(:universal, "config_management", LogStash::ConfigManagement::Extension)
LogStash::PLUGIN_REGISTRY.add(:modules, "arcsight",
                              LogStash::Modules::XpackScaffold.new("arcsight",
                                                                   File.join(File.dirname(__FILE__), "..", "..", "modules", "arcsight", "configuration"),
                                                                   ["basic", "trial", "standard", "gold", "platinum"]
                              ))

LogStash::PLUGIN_REGISTRY.add(:modules, "azure",
                              LogStash::Modules::XpackScaffold.new("azure",
                                                                   File.join(File.dirname(__FILE__), "..", "..", "modules", "azure", "configuration"),
                                                                   ["basic", "trial", "standard", "gold", "platinum"]
                              ))
LogStash::PLUGIN_REGISTRY.add(:filter, "azure_event", LogStash::Filters::AzureEvent)