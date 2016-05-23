# encoding: utf-8
require "json"

class PlatformConfig

  Platform = Struct.new(:name, :box, :type, :specific)

  DEFAULT_CONFIG_LOCATION = File.join(File.dirname(__FILE__), "config", "platforms.json").freeze

  attr_reader :platforms, :latest

  def initialize(config_path = DEFAULT_CONFIG_LOCATION)
    @config_path = config_path
    @platforms = []

    data = JSON.parse(File.read(@config_path))
    data["platforms"].each do |k, v|
      @platforms << Platform.new(k, v["box"], v["type"], v["specific"])
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
