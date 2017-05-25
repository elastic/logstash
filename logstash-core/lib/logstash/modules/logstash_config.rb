# encoding: utf-8
require "logstash/namespace"
require_relative "file_reader"

module LogStash module Modules class LogStashConfig
  def initialize(modul, settings)
    @directory = ::File.join(modul.directory, "logstash")
    @name = modul.module_name
    @settings = settings
  end

  def template
    ::File.join(@directory, "#{@name}.conf.erb")
  end

  def setting(value, default)
    @settings.fetch(value, default)
  end

  def elasticsearch_output_config
    hosts = "#{setting("var.output.elasticsearch.host", "localhost:9200")}"
    index = "#{@name}-#{setting("var.output.elasticsearch.index_suffix", "%{+YYYY.MM.dd}")}"
    password = "#{setting("var.output.elasticsearch.password", "changeme")}"
    user = "#{setting("var.output.elasticsearch.user", "elasticsearch")}"
    <<-CONF
elasticsearch {
hosts => [#{hosts}]
index => "#{index}"
password => "#{password}"
user => "#{user}"
manage_template => false
}
CONF
  end

  def config_string
    # process the template and settings
    # send back as a string
    renderer = ERB.new(FileReader.read(template))
    renderer.result(binding)
  end
end end end
