require "logstash/filters/base"
require "logstash/namespace"

require "geoscript"

# Converts data from WMTS access logs to geospatial information
#
# Given a grid, WMTS urls contain all the necessary information to find out
# which coordinates a requested tile belongs to.  Using a simple grok filter
# you can extract all the relevant information. This plugin then translates
# these information into coordinates in LV03 and WGS84.
#
# Example of a request: http://wmts4.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/20130213/21781/23/470/561.jpeg
#
# The current filter can be configured as follows in the configuration file:
# 
#  filter { 
#     # First, waiting for varnish log file formats (combined apache logs)
#     grok { match => [ "message", "%{COMBINEDAPACHELOG}" ] }
#     # Then, parameters 
#     grok {
#       match => ["request", "(?<wmts.version>([0-9\.]{5}))\/(?<wmts.layer>([a-z0-9\.-]*))\/default\/(?<wmts.release>([0-9]{8}))\/(?<wmts.reference-system>([0-9]*))\/(?<wmts.zoomlevel>([    0-9]*))\/(?<wmts.row>([0-9]*))\/(?<wmts.col>([0-9]*))\.(?<wmts.filetype>([a-zA-Z]*))"]
#     }
#     # actually passes the previously parsed message to the wmts plugin
#     wmts { }
#  }
#
#

# Author: Christian Wittwer <wittwerch AT gmail DOT com>
# Date: 2013-05-16
#
# Modifications by Pierre Mauduit <pierre DOT mauduit AT camptocamp DOT com>
# Date: 2014-01
#
# Summary: 
#  * Integrating geoscript ruby gem to manage reprojections 
#  * Adding some unit tests
#  * Adding some extra options to the plugin
#
class LogStash::Filters::Wmts < LogStash::Filters::Base

  config_name "wmts"
  milestone 3

  # configures the grid (by default, it is set to Swisstopo's WMTS grid)
  config :wmts_grid, :validate => :hash,
    :default => {
      :x_padding => 420000, 
      :y_padding => 350000,
      :tile_width => 256,
      :tile_height => 256,
      :zoomlevel_mapping => [ 4000, 3750, 3500, 3250, 3000, 2750, 2500, 2250, 2000,
        1750, 1500, 1250, 1000, 750, 650, 500, 250, 100, 50, 20, 10, 5, 2.5, 2, 1.5, 1, 0.5, 0.25, 0.1 ]
    }
  # configures the prefix
  config :prefix, :validate => :string, :default => "#{config_name}."

  # configures the output projection
  config :output_epsg, :validate => :string, :default => "epsg:4326"

  # configures the name of the field for the WMTS zoomlevel
  config :zoomlevel_field, :validate => :string, :default => "wmts.zoomlevel"

  # configures the name of the field for the column
  config :column_field, :validate => :string, :default => "wmts.col"

  # configures the name of the field for the row
  config :row_field, :validate => :string, :default => "wmts.row"

  # configures the name of the field for the reference system
  config :refsys_field, :validate => :string, :default => "wmts.reference-system"
  
  public
  def register
    # basic WMTS grid parameter checking
    raise "Bad WMTS grid provided, no :x_padding provided" if @wmts_grid[:x_padding].nil?
    raise "Bad WMTS grid provided, no :y_padding provided" if @wmts_grid[:y_padding].nil?
    raise "Bad WMTS grid provided, no :tile_width provided" if @wmts_grid[:tile_width].nil?
    raise "Bad WMTS grid provided, no :tile_height provided" if @wmts_grid[:tile_height].nil?
    if @wmts_grid[:zoomlevel_mapping].nil? || ! (@wmts_grid[:zoomlevel_mapping].is_a?(Array))
      raise "Bad WMTS grid provided, no :zoomlevel_mapping (or not an array) provided"
    end 
  end

  public
  def filter(event)
    

    begin
      # cast values from grok into integers
      zoomlevel = Integer(event[@zoomlevel_field])
      col = Integer(event[@column_field])
      row = Integer(event[@row_field])

      input_epsg = "epsg:#{event[@refsys_field]}"

      zlmapping = @wmts_grid[:zoomlevel_mapping][zoomlevel]
      raise ArgumentError if zlmapping.nil?
    rescue ArgumentError, TypeError, NoMethodError
      event["#{@prefix}errmsg"] = "Bad parameter received from the Grok filter"
      filter_matched(event)
      return
    end

    begin
      input_x = @wmts_grid[:x_padding] + (((col+0.5)*@wmts_grid[:tile_width]*zlmapping).floor)
      input_y = @wmts_grid[:y_padding] - (((row+0.5)*@wmts_grid[:tile_height]*zlmapping).floor)

      event["#{@prefix}service"] = "wmts"

      event["#{@prefix}input_epsg"] = input_epsg
      event["#{@prefix}input_x"] = input_x
      event["#{@prefix}input_y"] = input_y
      # add a combined field to the event. used for elaticsearch facets (heatmap!)
      event["#{@prefix}input_xy"] = "#{input_x},#{input_y}"

      # convert from input_epsg to output_epsg (if necessary)
      event["#{@prefix}output_epsg"] = @output_epsg

      unless input_epsg == @output_epsg
        input_p = GeoScript::Geom::Point.new input_x, input_y
        output_p = GeoScript::Projection.reproject input_p, input_epsg, @output_epsg
        event["#{@prefix}output_xy"] = "#{output_p.x},#{output_p.y}"
        event["#{@prefix}output_x"] = output_p.x
        event["#{@prefix}output_y"] = output_p.y
      else
        # no reprojection needed
        event["#{@prefix}output_xy"] = "#{input_x},#{input_y}"
        event["#{@prefix}output_x"] = input_x
        event["#{@prefix}output_y"] = input_y
      end
    rescue 
      event["#{@prefix}errmsg"] = "Unable to reproject tile coordinates"
    end
    # filter matched => make changes persistent
    filter_matched(event)

    end # def filter
end
