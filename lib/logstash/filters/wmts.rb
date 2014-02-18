require "logstash/filters/base"
require "logstash/namespace"

#
# This filter converts data from OGC WMTS (Web Map Tile Service) URLs to
# geospatial information, and expands the logstash event accordingly. See
# http://www.opengeospatial.org/standards/wmts for more information about WMTS. 
#
# Given a grid, WMTS urls contain all the necessary information to find out
# which coordinates a requested tile belongs to.  Using a simple grok filter
# you can extract all the relevant information. This plugin then translates
# these information into coordinates in LV03 and WGS84.
#
# Here is an example of such a request: 
# http://wmts4.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/20130213/21781/23/470/561.jpeg
#
# The current filter can be configured as follows in the configuration file:
# 
#  filter { 
#     # First, waiting for varnish log file formats (combined apache logs)
#     grok { match => [ "message", "%{COMBINEDAPACHELOG}" ] }
#     # Then, parameters 
#     grok {
#       [ 
#         "request",
#         "(?<wmts.version>([0-9\.]{5}))\/(?<wmts.layer>([a-z0-9\.-]*))\/default\/(?<wmts.release>([0-9]*))\/(?<wmts.reference-system>([a-z0-9]*))\/(?<wmts.zoomlevel>([0-9]*))\/(?<wmts.row>([0-9]*))\/(?<wmts.col>([0-9]*))\.(?<wmts.filetype>([a-zA-Z]*))"
#       ]
#     }
#     # actually passes the previously parsed message to the wmts plugin
#     wmts { }
#  }
#
# By default, the filter is configured to parse requests made on WMTS servers
# configured with the Swisstopo WMTS grid, but this can be customized, by
# setting the following parameters:
#
# - x_origin: the abscissa origin of the grid 
# - y_origin: the ordinate origin of the grid
# - tile_width: the width of the produced image tiles
# - tile_height: the height of the image tiles
# - resolutions: the array of resolutions for this wmts grid
# 
# Additionnally, the following parameters can be set:
#
# - prefix: the prefix used on the added variables, by default 'wmts.'
# - output_epsg: the output projection, classical one by default (lat/lon /
#   epsg:4326)
# - zoomlevel_field: the name of the field where the filter can find the
#   previously extracted zoomlevel, defaults to 'wmts.zoomlevel'
# - column_field: same for column, defaults to 'wmts.col'
# - row_field: same, defaults to 'wmts.row'
# - refsys_field: same, defaults to 'wmts.reference-system'
#   Note: if the reference system is different from the output_epsg, a
#   reprojection of the coordinates will take place.
# - epsg_mapping: sometimes, the reference-system can be given as a string
#   ('swissgrid' for instance). This parameter allows to set a mapping between
#   a regular name and the epsg number of a projection, e.g.:
#   { 'swissgrid' => 21781 }
#

class LogStash::Filters::Wmts < LogStash::Filters::Base

  config_name "wmts"
  milestone 3


  # WMTS grid configuration (by default, it is set to Swisstopo's WMTS grid)
  # x_origin
  config :x_origin, :validate => :number, :default => 420000
  # y_origin
  config :y_origin, :validate => :number, :default => 350000
  # tile_width
  config :tile_width, :validate => :number, :default => 256
  # tile_height
  config :tile_height, :validate => :number, :default => 256
  # resolutions
  config :resolutions, :validate => :array, :default => [ 4000, 3750, 3500, 3250, 3000, 2750, 2500, 2250, 2000,
        1750, 1500, 1250, 1000, 750, 650, 500, 250, 100, 50, 20, 10, 5, 2.5, 2, 1.5, 1, 0.5, 0.25, 0.1 ]

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
  
  # configures a mapping between named projections and their actual EPSG code.
  # Some production WMTS use a regular name instead of a numerical value for
  # the projection code. This parameter allows to define a custom mapping
  config :epsg_mapping, :validate => :hash, :default => {} 

  public
  def register
    require "geoscript"
 end

  public
  def filter(event)
    begin
      # cast values extracted upstream into integers
      zoomlevel = Integer(event[@zoomlevel_field])
      col = Integer(event[@column_field])
      row = Integer(event[@row_field])

      # checks if a mapping exists for the reference system extracted
      translated_epsg = @epsg_mapping[event[@refsys_field]] || event[@refsys_field] 
      input_epsg = "epsg:#{translated_epsg}"

      resolution = @resolutions[zoomlevel]
      raise ArgumentError if resolution.nil?
    rescue ArgumentError, TypeError, NoMethodError
      event["#{@prefix}errmsg"] = "Bad parameter received from upstream filter"
      filter_matched(event)
      return
    end

    begin
      input_x = @x_origin + (((col+0.5)*@tile_width*resolution).floor)
      input_y = @y_origin - (((row+0.5)*@tile_height*resolution).floor)

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
