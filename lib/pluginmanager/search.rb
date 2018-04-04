# encoding: utf-8
require 'rubygems/spec_fetcher'
require "pluginmanager/command"

class LogStash::PluginManager::Search < LogStash::PluginManager::Command

  parameter "[REGEX]", "regular expression to use"

  option "--author", "NAME", "Show only plugins authored by this name"

  def execute
    LogStash::Bundler.setup!({:without => [:build, :development]})
    fetcher = Gem::SpecFetcher.fetcher
    regex_obj = Regexp.new(regex)
    results = fetcher.detect(:latest) {|name_tuple| name_tuple.name.match(regex_obj) }
    results.map {|name_tuple, source| source.fetch_spec(name_tuple) }.each do |spec|
      next unless spec.metadata["logstash_plugin"] == "true"
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
