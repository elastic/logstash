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

  def kibana_index_hacks
    # Copied from libbeat/dashboards/importer.go
    # CreateKibanaIndex creates the kibana index if it doesn't exists and sets
    # some index properties which are needed as a workaround for:
    # https://github.com/elastic/beats-dashboards/issues/94
    # with kibana 5.4.0 this hack failed to be applied.
    ha = '{"settings": {"index":{"mapping":{"single_type": false}}}}'
    hb = '{"search": {"properties": {"hits": {"type": "integer"}, "version": {"type": "integer"}}}}'
    [
      KibanaBaseResource.new(@index_name, "not-used", "not-used", ha),
      KibanaBaseResource.new(@index_name, "not-used", "not-used", hb)
    ]
  end

  def resources
    list = [] # kibana_index_hacks
    dashboards.each do |board|
      extract_panels_into(board, list)
    end
    list
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
  end
end end end
