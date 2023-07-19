# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "logstash/util"

module LogStash module Modules module SettingsMerger
  include LogStash::Util::Loggable
  extend self

  # cli_settings Array or LogStash::Util::ModulesSettingArray
  # yml_settings Array or LogStash::Util::ModulesSettingArray
  def merge(cli_settings, yml_settings)
    # both args are arrays of hashes, e.g.
    # [{"name"=>"mod1", "var.input.tcp.port"=>"3333"}, {"name"=>"mod2"}]
    # [{"name"=>"mod1", "var.input.tcp.port"=>2222, "var.kibana.username"=>"rupert", "var.kibana.password"=>"fotherington"}, {"name"=>"mod3", "var.input.tcp.port"=>4445}]
    merged = []
    # union and group_by preserves order
    # union will also coalesce identical hashes
    # this "|" operator is provided to Java List by RubyJavaIntegration
    union_of_settings = (cli_settings | yml_settings)
    grouped_by_name = union_of_settings.group_by {|e| e["name"]}
    grouped_by_name.each do |_, array|
      if array.size == 2
        merged << array.last.merge(array.first)
      else
        merged.concat(array)
      end
    end
    merged
  end

  def merge_cloud_settings(module_settings, logstash_settings)
    cloud_id = logstash_settings.get("cloud.id")
    cloud_auth = logstash_settings.get("cloud.auth")
    if cloud_id.nil?
      if cloud_auth.nil?
        return # user did not specify cloud settings
      else
        raise ArgumentError.new("Cloud Auth without Cloud Id")
      end
    end
    if logger.debug?
      settings_copy = LogStash::Util.deep_clone(module_settings)
    end

    module_settings["var.kibana.scheme"] = cloud_id.kibana_scheme
    module_settings["var.kibana.host"] = cloud_id.kibana_host
    # elasticsearch client does not use scheme, it URI parses the host setting
    module_settings["var.elasticsearch.hosts"] = "#{cloud_id.elasticsearch_scheme}://#{cloud_id.elasticsearch_host}"
    unless cloud_auth.nil?
      module_settings["var.elasticsearch.username"] = cloud_auth.username
      module_settings["var.elasticsearch.password"] = cloud_auth.password
      module_settings["var.kibana.username"] = cloud_auth.username
      module_settings["var.kibana.password"] = cloud_auth.password
    end
    if logger.debug?
      format_module_settings(settings_copy, module_settings).each {|line| logger.debug(line)}
    end
  end

  def merge_kibana_auth!(module_settings)
    module_settings["var.kibana.username"] = module_settings["var.elasticsearch.username"] if module_settings["var.kibana.username"].nil?
    module_settings["var.kibana.password"] = module_settings["var.elasticsearch.password"] if module_settings["var.kibana.password"].nil?
  end

  def format_module_settings(settings_before, settings_after)
    output = []
    output << "-------- Module Settings ---------"
    settings_after.each do |setting_name, setting|
      setting_before = settings_before.fetch(setting_name, "")
      line = "#{setting_name}: '#{setting}'"
      if setting_before != setting
        line.concat(", was: '#{setting_before}'")
      end
      output << line
    end
    output << "-------- Module Settings ---------"
    output
  end
end end end
