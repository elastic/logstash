# encoding: utf-8
require "logstash/namespace"
require "logstash/logging"

require_relative "file_reader"
require_relative "kibana_resource"
require_relative "kibana_base_resource"

module LogStash module Modules class KibanaConfig
  include LogStash::Util::Loggable

  ALLOWED_DIRECTORIES = ["search", "visualization"]

  attr_reader :index_name

  # We name it `modul` here because `module` has meaning in Ruby.
  def initialize(modul, settings)
    @directory = ::File.join(modul.directory, "kibana")
    @name = modul.module_name
    @settings = settings
    @index_name = settings.fetch("dashboards.kibana_index", ".kibana")
  end

  def dashboards
    # there can be more than one dashboard to load
    filenames = FileReader.read_json(dynamic("dashboard"))
    filenames.map do |filename|
      KibanaResource.new(@index_name, "dashboard", dynamic("dashboard", filename))
    end
  end

  def index_pattern
    pattern_name = "#{@name}-*"
    default_index_json = '{"defaultIndex": "#{pattern_name}"}'
    default_index_content_id = @settings.fetch("index_pattern.kibana_version", "5.5.1")
    [
      KibanaResource.new(@index_name, "index-pattern", dynamic("index-pattern"),nil, pattern_name),
      KibanaResource.new(@index_name, "config", nil, default_index_json, default_index_content_id)
    ]
  end

  def resources
    list = index_pattern
    dashboards.each do |board|
      extract_panels_into(board, list)
    end
    list.concat(extract_saved_searches(list))
  end

  private

  def dynamic(dynamic_folder, filename = @name)
    ::File.join(@directory, dynamic_folder, "#{filename}.json")
  end

  def extract_panels_into(dashboard, list)
    list << dashboard

    dash = FileReader.read_json(dashboard.content_path)

    if !dash.is_a?(Hash)
      logger.warn("Kibana dashboard JSON is not an Object", :module => @name)
      return
    end

    panelsjson = dash["panelsJSON"]

    if panelsjson.nil?
      logger.info("No panelJSON key found in kibana dashboard", :module => @name)
      return
    end

    begin
      panels = LogStash::Json.load(panelsjson)
    rescue => e
      logger.error("JSON parse error when reading kibana panelsJSON", :module => @name)
      return
    end

    panels.each do |panel|
      panel_type = panel["type"]
      if ALLOWED_DIRECTORIES.member?(panel_type)
        list << KibanaResource.new(@index_name, panel_type, dynamic(panel_type, panel["id"]))
      else
        logger.warn("panelJSON contained unknown type", :type => panel_type)
      end
    end

    def extract_saved_searches(list)
      result = [] # must not add to list while iterating
      list.each do |resource|
        next unless resource.contains?("savedSearchId")
        content = resource.content_as_object
        next if content.nil?
        saved_search = content["savedSearchId"]
        next if saved_search.nil?
        ss_resource = KibanaResource.new(@index_name, "search", dynamic("search", saved_search))
        next if list.member?(ss_resource) || result.member?(ss_resource)
        result << ss_resource
      end
      result
    end
  end
end end end
