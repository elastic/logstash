# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "tempfile"

# Add GeoIP fields from Maxmind database
#
# GeoIP filter, adds information about the geographical location of IP addresses.
#
# Starting at version 1.3.0 of logstash, a [geoip][location] field is created if
# the GeoIP lookup returns a latitude and longitude. The field is stored in
# [GeoJSON](http://geojson.org/geojson-spec.html) format. Additionally,
# the default Elasticsearch template provided with the
# [elasticsearch output](../outputs/elasticsearch.html)
# maps the [geoip][location] field to a [geo_point](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping-geo-point-type.html).
#
# As this field is a geo\_point _and_ it is still valid GeoJSON, you get
# the awesomeness of Elasticsearch's geospatial query, facet and filter functions
# and the flexibility of having GeoJSON for all other applications (like Kibana's
# [bettermap panel](https://github.com/elasticsearch/kibana/tree/master/src/app/panels/bettermap)).
#
# Logstash releases ship with the GeoLiteCity database made available from
# Maxmind with a CCA-ShareAlike 3.0 license. For more details on GeoLite, see
# <http://www.maxmind.com/en/geolite>.
class LogStash::Filters::GeoIP < LogStash::Filters::Base
  config_name "geoip"
  milestone 1

  # GeoIP database file to use, Country, City, ASN, ISP and organization
  # databases are supported
  #
  # If not specified, this will default to the GeoLiteCity database that ships
  # with logstash.
  config :database, :validate => :path

  # The field containing the IP address or hostname to map via geoip. If
  # this field is an array, only the first value will be used.
  config :source, :validate => :string, :required => true

  # Array of geoip fields that we want to be included in our event.
  #
  # Possible fields depend on the database type. By default, all geoip fields
  # are included in the event.
  #
  # For the built in GeoLiteCity database, the following are available:
  # city\_name, continent\_code, country\_code2, country\_code3, country\_name,
  # dma\_code, ip, latitude, longitude, postal\_code, region\_name, timezone
  config :fields, :validate => :array

  # Specify into what field you want the geoip data.
  # This can be useful for example if you have a src\_ip and dst\_ip and want
  # information of both IP's.
  #
  # If you save the data to another target than "geoip" and want to use the
  # geo\_point related functions in elasticsearch, you need to alter the template
  # provided with the elasticsearch output and configure the output to use the
  # new template.
  #
  # Even if you don't use the geo\_point mapping, the [target][location] field
  # is still valid GeoJSON.
  config :target, :validate => :string, :default => 'geoip'

  public
  def register
    require "geoip"
    if @database.nil?
      if __FILE__ =~ /^(jar:)?file:\/.+!.+/
        begin
          # Running from a jar, assume GeoLiteCity.dat is at the root.
          jar_path = [__FILE__.split("!").first, "/GeoLiteCity.dat"].join("!")
          tmp_file = Tempfile.new('logstash-geoip')
          tmp_file.write(File.read(jar_path))
          tmp_file.close # this file is reaped when ruby exits
          @database = tmp_file.path
        rescue => ex
          raise "Failed to cache, due to: #{ex}\n#{ex.backtrace}"
        end
      else
        if File.exists?("GeoLiteCity.dat")
          @database = "GeoLiteCity.dat"
        elsif File.exists?("vendor/geoip/GeoLiteCity.dat")
          @database = "vendor/geoip/GeoLiteCity.dat"
        else
          raise "You must specify 'database => ...' in your geoip filter"
        end
      end
    end
    @logger.info("Using geoip database", :path => @database)
    @geoip = ::GeoIP.new(@database)

    @geoip_type = case @geoip.database_type
    when GeoIP::GEOIP_CITY_EDITION_REV0, GeoIP::GEOIP_CITY_EDITION_REV1
      :city
    when GeoIP::GEOIP_COUNTRY_EDITION
      :country
    when GeoIP::GEOIP_ASNUM_EDITION
      :asn
    when GeoIP::GEOIP_ISP_EDITION, GeoIP::GEOIP_ORG_EDITION
      :isp
    else
      raise RuntimeException.new "This GeoIP database is not currently supported"
    end

  end # def register

  public
  def filter(event)
    return unless filter?(event)
    geo_data = nil

    begin
      ip = event[@source]
      ip = ip.first if ip.is_a? Array
      geo_data = @geoip.send(@geoip_type, ip)
    rescue SocketError => e
      @logger.error("IP Field contained invalid IP address or hostname", :field => @field, :event => event)
    rescue Exception => e
      @logger.error("Unknown error while looking up GeoIP data", :exception => e, :field => @field, :event => event)
    end

    return if geo_data.nil?

    geo_data_hash = geo_data.to_hash
    geo_data_hash.delete(:request)
    event[@target] = {} if event[@target].nil?
    geo_data_hash.each do |key, value|
      next if value.nil? || (value.is_a?(String) && value.empty?)
      if @fields.nil? || @fields.empty?
        # no fields requested, so add all geoip hash items to
        # the event's fields.
        # convert key to string (normally a Symbol)
        event[@target][key.to_s] = value
      elsif @fields.include?(key.to_s)
        # Check if the key is in our fields array
        # convert key to string (normally a Symbol)
        event[@target][key.to_s] = value
      end
    end # geo_data_hash.each
    if event[@target].key?('latitude') && event[@target].key?('longitude')
      # If we have latitude and longitude values, add the location field as GeoJSON array
      event[@target]['location'] = [ event[@target]["longitude"].to_f, event[@target]["latitude"].to_f ]
    end
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::GeoIP
