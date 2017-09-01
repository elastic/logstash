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
end end end
