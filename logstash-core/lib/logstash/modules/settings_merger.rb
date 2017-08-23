# encoding: utf-8
require "logstash/namespace"

module LogStash module Modules class SettingsMerger
  def self.merge(cli_settings, yml_settings)
    # both args are arrays of hashes, e.g.
    # [{"name"=>"mod1", "var.input.tcp.port"=>"3333"}, {"name"=>"mod2"}]
    # [{"name"=>"mod1", "var.input.tcp.port"=>2222, "var.kibana.username"=>"rupert", "var.kibana.password"=>"fotherington"}, {"name"=>"mod3", "var.input.tcp.port"=>4445}]
    merged = []
    # union and group_by preserves order
    # union will also coalesce identical hashes
    union_of_settings = (cli_settings | yml_settings)
    grouped_by_name = union_of_settings.group_by{|e| e["name"]}
    grouped_by_name.each do |name, array|
      if array.size == 2
        merged << array.first.merge(array.last)
      else
        merged.concat(array)
      end
    end
    merged
  end

  def self.merge_cloud_settings(module_settings, logstash_settings)
    cloud_id = logstash_settings.get("cloud.id")
    cloud_auth = logstash_settings.get("cloud.auth")
    if cloud_id.nil?
      if cloud_auth.nil?
        return # user did not specify cloud settings
      else
        raise ArgumentError.new("Cloud Auth without Cloud Id")
      end
    end
    module_settings["var.kibana.scheme"] = "https"
    module_settings["var.kibana.host"] = cloud_id.kibana_host
    module_settings["var.elasticsearch.hosts"] = cloud_id.elasticsearch_host
    unless cloud_auth.nil?
      module_settings["var.elasticsearch.username"] = cloud_auth.username
      module_settings["var.elasticsearch.password"] = cloud_auth.password.value
      module_settings["var.kibana.username"] = cloud_auth.username
      module_settings["var.kibana.password"] = cloud_auth.password.value
    end
  end
end end end
