# encoding: utf-8
require "json"
require "ostruct"

# This is a wrapper to encapsulate the logic behind the different platforms we test with, 
# this is done here in order to simplify the necessary configuration for bootstrap and interactions
# necessary later on in the tests phases.
#
class PlatformConfig

  # Abstract the idea of a platform, aka an OS
  class Platform

    attr_reader :name, :box, :type, :bootstrap, :experimental

    def initialize(name, data)
      @name = name
      @box  = data["box"]
      @type = data["type"]
      @experimental = data["experimental"] || false
      configure_bootstrap_scripts(data)
    end

    private

    def configure_bootstrap_scripts(data)
      @bootstrap = OpenStruct.new(:privileged     => "sys/#{type}/bootstrap.sh",
                                  :non_privileged => "sys/#{type}/user_bootstrap.sh")
      ##
      # for now the only specific bootstrap scripts are ones need
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

  def filter_type(type_name, options={})
    experimental = options.fetch("experimental", false)
    @platforms.select do |platform|
      (type_name.nil? ? true : platform.type == type_name) &&
          platform.experimental == experimental
    end
  end

  def select_names_for(platform, options={})
    filter_options = { "experimental" => options.fetch("experimental", false) }
    filter_type(platform, filter_options).map{ |p| p.name }
  end

  def types
    @platforms.collect(&:type).uniq.sort
  end
end
