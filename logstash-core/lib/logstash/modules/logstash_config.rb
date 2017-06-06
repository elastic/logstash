# encoding: utf-8
require "logstash/namespace"
require_relative "file_reader"

module LogStash module Modules class LogStashConfig

  # We name it `modul` here because `module` has meaning in Ruby.
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

  def elasticsearch_output_config(type_string = nil)
    hosts = setting("var.output.elasticsearch.hosts", "localhost:9200").split(',').map do |s|
      '"' + s.strip + '"'
    end.join(',')
    index = "#{@name}-#{setting("var.output.elasticsearch.index_suffix", "%{+YYYY.MM.dd}")}"
    password = "#{setting("var.output.elasticsearch.password", "changeme")}"
    user = "#{setting("var.output.elasticsearch.user", "elastic")}"
    document_type_line = type_string ? "document_type => #{type_string}" : ""
    <<-CONF
elasticsearch {
hosts => [#{hosts}]
index => "#{index}"
password => "#{password}"
user => "#{user}"
manage_template => false
#{document_type_line}
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
