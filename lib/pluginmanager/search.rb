# encoding: utf-8
require 'rubygems/spec_fetcher'
require "pluginmanager/command"

class LogStash::PluginManager::Search < LogStash::PluginManager::Command

  parameter "[PATTERN]", "pattern to look for"

  option "--author", "NAME", "Show only plugins authored by this name"

  def execute
    LogStash::Bundler.setup!({:without => [:build, :development]})
    fetcher = Gem::SpecFetcher.fetcher
    fetcher.detect(:latest) do |name_tuple|
      File.fnmatch?(pattern, name_tuple.name)
    end.map {|name_tuple, source| source.fetch_spec(name_tuple) }.each do |spec|
      next unless spec.metadata && spec.metadata["logstash_plugin"] == "true"
      next unless spec.platform == 'java' || (spec.platform.is_a?(Gem::Platform) && spec.platform.os == 'java')
      if author
        next unless spec.authors.include?(author)
      end
      puts "#{spec.name} - #{spec.version}"
      puts "  Date: #{spec.date}"
      puts "  Author: #{spec.authors.join(', ')}"
      puts "  Homepage: #{spec.homepage}"
      puts "  Description: #{spec.summary}"
    end
  end
end
