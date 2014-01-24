require "logstash/filters/base"
require "logstash/namespace"

require "geoscript"
require "uri"

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
  
  public
  def register
  end

  public
  def filter(event)
 
    # Detects if the apache combined log grok filter has been executed before
    # we use request if available.
    msg = event["request"].nil? ? event["message"] : event["request"]

    msg.downcase!
    # not a valid WMS request
    return unless msg.include? "service=wms"

    event['gis.service'] = 'wms'

    parsed_uri = URI(msg)
    wms_parameters = Hash[*URI.decode_www_form(parsed_uri.query).flatten]

    @wms_fields.each do |f|

      # if the parameter has been found in the uri,
      # then parse it and add infos to the event
      
      unless wms_parameters[f].nil?

        # bounding box parsing / reprojecting
        if f == 'bbox'
          bbox = wms_parameters[f].split(",")
          bbox.map!(&:to_f)
          in_proj = wms_parameters['crs'] || wms_parameters['srs'] || @output_epsg
          # reprojection needed
          if in_proj != @output_epsg
            @logger.warn("GeoScript reprojections could be inaccurate !")
            event["gis.original_bbox.minx"] = bbox[0]
            event["gis.original_bbox.miny"] = bbox[1]
            event["gis.original_bbox.maxx"] = bbox[2]
            event["gis.original_bbox.maxy"] = bbox[3]

            max_xy = GeoScript::Geom::Point.new bbox[2], bbox[3]
            min_xy = GeoScript::Geom::Point.new bbox[0], bbox[1]

            max_reproj = GeoScript::Projection.reproject max_xy, in_proj, @output_epsg
            min_reproj = GeoScript::Projection.reproject min_xy, in_proj, @output_epsg

            bbox = [min_reproj.get_x, min_reproj.get_y, max_reproj.get_x, max_reproj.get_y ]
          end
          event["gis.bbox.minx"] = bbox[0]
          event["gis.bbox.miny"] = bbox[1]
          event["gis.bbox.maxx"] = bbox[2]
          event["gis.bbox.maxy"] = bbox[3]
 
        elsif f == "layers"
          event["gis.#{f}"] = wms_parameters[f].split(",")
        # no extra parsing of the parameter needed
        else
          event["gis.#{f}"] = wms_parameters[f]
        end
      end
    end

    filter_matched(event)
  end

end
