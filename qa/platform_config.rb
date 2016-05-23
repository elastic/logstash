# encoding: utf-8
require "json"
require "ostruct"

class PlatformConfig


  class Platform

    attr_reader :name, :box, :type, :bootstrap

    def initialize(name, data)
      @name = name
      @box  = data["box"]
      @type = data["type"]
      initialize_bootstrap_scripts(data)
    end

    private

    def initialize_bootstrap_scripts(data)
      @bootstrap = OpenStruct.new(:privileged     => "sys/#{type}/bootstrap.sh",
                                  :non_privileged => "sys/#{type}/user_bootstrap.sh")
      ##
      # for now the only specific boostrap scripts are ones need
      # with privileged access level, whenever others are also
      # required we can update this section as well with the same pattern.
      ##
      @bootstrap.privileged = "sys/#{type}/#{name}/bootstrap.sh" if data["specific"]
    end
  end

  DEFAULT_CONFIG_LOCATION = File.join(File.dirname(__FILE__), "config", "platforms.json").freeze

  attr_reader :platforms, :latest

  def initialize(config_path = DEFAULT_CONFIG_LOCATION)
    @config_path = config_path
    @platforms = []

    data = JSON.parse(File.read(@config_path))
    data["platforms"].each do |k, v|
      @platforms << Platform.new(k, v)
    end
    @platforms.sort! { |a, b| a.name <=> b.name }
    @latest = data["latest"]
  end

  def find!(platform_name)
    result = @platforms.find { |platform| platform.name == platform_name }.first
    if result.nil?
      raise "Cannot find platform named: #{platform_name} in @config_path"
    else
      return result
    end
  end

  def each(&block)
    @platforms.each(&block)
  end

  def filter_type(type_name)
    @platforms.select { |platform| platform.type == type_name }
  end

  def select_names_for(platform=nil)
    !platform.nil? ? filter_type(platform).map{ |p| p.name } : ""
  end

  def types
    @platforms.collect(&:type).uniq.sort
  end
end
