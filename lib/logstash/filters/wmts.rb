require "logstash/filters/base"
require "logstash/namespace"

require "geoscript"

# Converts data from WMTS access logs to geospatial information
# 
# WMTS access logs contains all the necessary information to find out which coordinates a tile belongs to. 
# Using a simple grok filter you can extract all the relevant information. This plugin then translates these information into coordinates in LV03 and WGS84.
#
# Example: http://wmts4.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/20130213/21781/23/470/561.jpeg
# Grok pattern: "(?<gis.version>([0-9\.]{5}))\/(?<gis.layer>([a-z0-9\.-]*))\/default\/(?<gis.release>([0-9]{8}))\/(?<gis.reference-system>([0-9]*))\/(?<gis.zoo    mlevel>([0-9]*))\/(?<gis.row>([0-9]*))\/(?<gis.col>([0-9]*))\.(?<gis.filetype>([a-zA-Z]*))"
#
# filter {
#   grok {
#       type => varnish
#       pattern => "(?<gis.version>([0-9\.]{5}))\/(?<gis.layer>([a-z0-9\.-]*))\/default\/(?<gis.release>([0-9]{8}))\/(?<gis.reference-system>([0-9]*))\/(?<gis.zoomlevel>([    0-9]*))\/(?<gis.row>([0-9]*))\/(?<gis.col>([0-9]*))\.(?<gis.filetype>([a-zA-Z]*))"
#   }
#   wmts {
#     zoomlevel => "gis.zoomlevel"
#   }
# }
#
# Author: Christian Wittwer <wittwerch@gmail.com>
# Date: 2013-05-16
#
# Modifications by Pierre Mauduit <pierre DOT mauduit AT camptocamp DOT com>
# Date: 2014-01
# Summary: 
#  * Integrating the geoscript gem to allow reprojections 
#  * Adding some unit tests
#  * Adding some extra options

class LogStash::Filters::Wmts < LogStash::Filters::Base

  config_name "wmts"
  milestone 3

  public
  def register

    @mapping = {
      0 => 4000,
      1 => 3750,
      2 => 3500,
      3 => 3250,
      4 => 3000,
      5 => 2750,
      6 => 2500,
      7 => 2250,
      8 => 2000,
      9 => 1750,
      10 => 1500,
      11 => 1250,
      12 => 1000,
      13 => 750,
      14 => 650,
      15 => 500,
      16 => 250,
      17 => 100,
      18 => 50,
      19 => 20,
      20 => 10,
      21 => 5,
      22 => 2.5,
      23 => 2,
      24 => 1.5,
      25 => 1,
      26 => 0.5,
      27 => 0.25,
      28 => 0.1
    }

  end # def register

  public
  def filter(event)
    
    return unless filter?(event)

    puts event.inspect
    # return if the event does not have the necessary fields
    return unless event.include?("gis.zoomlevel")
    return unless event.include?("gis.col")
    return unless event.include?("gis.row")

    # cast values into integers
    zoomlevel = Integer(event["gis.zoomlevel"])
    col = Integer(event["gis.col"])
    row = Integer(event["gis.row"])

    @logger.debug("zoomlevel: #{zoomlevel}, row: #{row}, col: #{col}")

    zlmapping = @mapping[zoomlevel]
    return if zlmapping.nil?

    event["gis.service"] = "wmts"

    # convert row and col into LV03 x and y
    lv03_x = 420000 + (((col+0.5)*256*zlmapping).floor)
    lv03_y = 350000 - (((row+0.5)*256*zlmapping).floor)

    # add new LV03 values to the event
    event["gis.lv03_x"] = lv03_x
    event["gis.lv03_y"] = lv03_y
    # add a combined field to the event. used for elaticsearch facets (heatmap!)
    event["gis.lv03_xy"] = "#{lv03_x},#{lv03_y}"

    # convert LV03 to WGS84

    lv03_p = GeoScript::Geom::Point.new lv03_x, lv03_y
    wgs84_p = GeoScript::Projection.reproject lv03_p, 'epsg:21781', 'epsg:4326'

    event['wgs84.wkt'] = wgs84_p.to_wkt 
    
    # add new WGS84 values to the event
    event["gis.wgs84_lat"] = wgs84_p.y
    event["gis.wgs84_lng"] = wgs84_p.x
    # add a combined field to the event. used for elaticsearch facets (heatmap!)
    event["gis.wgs84_latlng"] = "#{event["gis.wgs84_lat"]},#{event["gis.wgs84_lng"]}" 

    # filter matched => make changes persistent
    filter_matched(event)

    end # def filter
end
