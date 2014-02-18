require "logstash/filters/base"
require "logstash/namespace"

#
# This filter allows to parse WMS (Web-Map Service) queries.
#
# It can be used to extract the bounding box from the requests (in case of
# GetMap queries for example), and the usual parameters defined in the OGC WMS
# standard. See http://www.opengeospatial.org/standards/wms for more infos.
#
# The list of expected parameter can be customized by giving a specific array
# of fields, but the default one should already fill in the logstash event with
# the most common information we can find in regular WMS queries (service,
# version, layers, requested projection, output format ...).
# 
# The module also permits to reproject the bounding boxes from getmap requests,
# using the GeoScript (Gem / Wrapper to the Geotools java library).
#
# It can be customized using the following parameters:
#
# - output_epsg: the output projection to be used when setting the x/y
#   coordinates, default to regular lat/long wgs84 ('epsg:4326')
# - wms_fields: The fields that have to be potentially extracted from the query
# - prefix: the string that will be used to prefix the variables added to the
#   logstash event, defaults to 'wms.'
#

class LogStash::Filters::Wms < LogStash::Filters::Base

  config_name "wms"
  milestone 3

  # epsg for the output
  config :output_epsg, :validate => :string, :default => 'epsg:4326'


  # default wms parameters to extract
  config :wms_fields, :validate => :array, :default => [
    'service', 'version', 'request', 'layers', 'styles', 'crs', 'srs',
    'bbox', 'width', 'height', 'format', 'transparent', 'bgcolor',
    'bgcolor', 'exceptions', 'time', 'elevation', 'wfs' 
  ]

  # prefix for parsed elements added by the plugin
  config :prefix, :validate => :string, :default => "#{config_name}."

  public
  def register
    require "geoscript"
    require "uri"
 end

  public
  def filter(event)

    # we use the request field if available, else fallback onto message
    msg = event["request"].nil? ? event["message"] : event["request"]

    msg.downcase!

    # not a valid WMS request
    return unless msg.include? "service=wms"

    begin
      parsed_uri = URI(msg)
      wms_parameters = Hash[*URI.decode_www_form(parsed_uri.query).flatten]
    rescue # TODO: be more specific
      event["#{@prefix}errmsg"] = "Unable to parse the provided request URI: #{msg}"
      # at this point, we won't be able to do better
      filter_matched(event)
      return
    end

    @wms_fields.each do |f|

      # if the parameter has been found in the uri,
      # then parses it and adds infos to the event

      unless wms_parameters[f].nil?

        # bounding box parsing / reprojecting
        if f == 'bbox'
          begin
            bbox = wms_parameters[f].split(",")
            bbox.map!(&:to_f)
            raise ArgumentError.new if bbox.length != 4 
          rescue
            event["#{@prefix}errmsg"] = "Unable to parse the bounding box"
            next
          end
          in_proj = wms_parameters['crs'] || wms_parameters['srs'] || @output_epsg

          event["#{@prefix}input_bbox.minx"] = bbox[0]
          event["#{@prefix}input_bbox.miny"] = bbox[1]
          event["#{@prefix}input_bbox.maxx"] = bbox[2]
          event["#{@prefix}input_bbox.maxy"] = bbox[3]

          # reprojection needed
          if in_proj != @output_epsg
            begin
              max_xy = GeoScript::Geom::Point.new bbox[2], bbox[3]
              min_xy = GeoScript::Geom::Point.new bbox[0], bbox[1]

              max_reproj = GeoScript::Projection.reproject max_xy, in_proj, @output_epsg
              min_reproj = GeoScript::Projection.reproject min_xy, in_proj, @output_epsg

              bbox = [ min_reproj.get_x, min_reproj.get_y, max_reproj.get_x, max_reproj.get_y ]
            rescue
              event["#{@prefix}errmsg"] = "Unable to reproject the bounding box"
              next
            end
          end
          event["#{@prefix}output_bbox.minx"] = bbox[0]
          event["#{@prefix}output_bbox.miny"] = bbox[1]
          event["#{@prefix}output_bbox.maxx"] = bbox[2]
          event["#{@prefix}output_bbox.maxy"] = bbox[3]

        elsif f == "layers"
          event["#{@prefix}#{f}"] = wms_parameters[f].split(",")
          # Other parameters: no extra parsing of the parameter needed
        else
          event["#{@prefix}#{f}"] = wms_parameters[f]
        end
      end
    end
    filter_matched(event)
  end

end
