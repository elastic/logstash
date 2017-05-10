# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"
require "erb"

class LogStash::Modules
  include LogStash::Util::Loggable

  attr_reader :module_name
  def initialize(name, directory)
    @module_name = name
    @directory = directory  
  end

  def template
    ::File.join(@directory, "logstash/#{@module_name}.conf.erb")
  end

  class ModuleConfig

    def initialize(template, settings)
      @template = template
      @settings = settings
    end

    def setting(value, default)
      @settings.fetch(value, default)
    end

    def render
      # process the template and settings
      # send back as a string with no newlines (the '>' part)
      renderer = ERB.new(File.read(@template), 3, '>')
      renderer.result(binding)
    end
  end

  def config_string(settings = {})
    # settings should be the subset from the YAML file with a structure like
    # {"name" => "plugin name", "k1" => "v1", "k2" => "v2"}, etc.
    ModuleConfig.new(template, settings).render
  end

end # class LogStash::Modules