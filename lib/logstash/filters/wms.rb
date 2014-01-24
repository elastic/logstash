require "logstash/filters/base"
require "logstash/namespace"

require "geoscript"
require "uri"


class LogStash::Filters::Wms < LogStash::Filters::Base

  config_name "wms"
  milestone 3

  WMS_FIELDS = [
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

    WMS_FIELDS.each do |f|
      # if the parameter has been found in the uri,
      # then adds it to the event
      unless wms_parameters[f].nil?
        event["gis.#{f}"] = wms_parameters[f]
      end
    end

    filter_matched(event)
  end

end
