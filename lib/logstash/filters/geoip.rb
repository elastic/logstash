# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "tempfile"

# The GeoIP filter adds information about the geographical location of IP addresses,
# based on data from the Maxmind database.
#
# Starting with version 1.3.0 of Logstash, a [geoip][location] field is created if
# the GeoIP lookup returns a latitude and longitude. The field is stored in
# [GeoJSON](http://geojson.org/geojson-spec.html) format. Additionally,
# the default Elasticsearch template provided with the
# [elasticsearch output](../outputs/elasticsearch.html)
# maps the [geoip][location] field to a
# [geo_point](http://www.elasticsearch.org/guide/en/elasticsearch/reference/current/mapping-geo-point-type.html).
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
  milestone 3

  # The path to the GeoIP database file which Logstash should use. Country, City, ASN, ISP
  # and organization databases are supported.
  #
  # If not specified, this will default to the GeoLiteCity database that ships
  # with Logstash.
  config :database, :validate => :path

  # The field containing the IP address or hostname to map via geoip. If
  # this field is an array, only the first value will be used.
  config :source, :validate => :string, :required => true

  # An array of geoip fields to be included in the event.
  #
  # Possible fields depend on the database type. By default, all geoip fields
  # are included in the event.
  #
  # For the built-in GeoLiteCity database, the following are available:
  # `city\_name`, `continent\_code`, `country\_code2`, `country\_code3`, `country\_name`,
  # `dma\_code`, `ip`, `latitude`, `longitude`, `postal\_code`, `region\_name` and `timezone`.
  config :fields, :validate => :array

  # Specify the field into which Logstash should store the geoip data.
  # This can be useful, for example, if you have `src\_ip` and `dst\_ip` fields and
  # would like the GeoIP information of both IPs.
  #
  # If you save the data to a target field other than "geoip" and want to use the
  # geo\_point related functions in Elasticsearch, you need to alter the template
  # provided with the Elasticsearch output and configure the output to use the
  # new template.
  #
  # Even if you don't use the geo\_point mapping, the [target][location] field
  # is still valid GeoJSON.
  config :target, :validate => :string, :default => 'geoip'

  public
  def register
    require "geoip"
    if @database.nil?
      @database = LogStash::Environment.vendor_path("geoip/GeoLiteCity.dat")
      if !File.exists?(@database)
        raise "You must specify 'database => ...' in your geoip filter (I looked for '#{@database}'"
      end
    end
    @logger.info("Using geoip database", :path => @database)
    # For the purpose of initializing this filter, geoip is initialized here but
    # not set as a global. The geoip module imposes a mutex, so the filter needs
    # to re-initialize this later in the filter() thread, and save that access
    # as a thread-local variable.
    geoip_initialize = ::GeoIP.new(@database)

    @geoip_type = case geoip_initialize.database_type
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

    @threadkey = "geoip-#{self.object_id}"
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    geo_data = nil

    # Use thread-local access to GeoIP. The Ruby GeoIP module forces a mutex
    # around access to the database, which can be overcome with :pread.
    # Unfortunately, :pread requires the io-extra gem, with C extensions that
    # aren't supported on JRuby. If / when :pread becomes available, we can stop
    # needing thread-local access.
    if !Thread.current.key?(@threadkey)
      Thread.current[@threadkey] = ::GeoIP.new(@database)
    end

    begin
      ip = event[@source]
      ip = ip.first if ip.is_a? Array
      geo_data = Thread.current[@threadkey].send(@geoip_type, ip)
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
      if @fields.nil? || @fields.empty? || @fields.include?(key.to_s)
        # convert key to string (normally a Symbol)
        if value.is_a?(String)
          # Some strings from GeoIP don't have the correct encoding...
          value = case value.encoding
            # I have found strings coming from GeoIP that are ASCII-8BIT are actually
            # ISO-8859-1...
            when Encoding::ASCII_8BIT; value.force_encoding(Encoding::ISO_8859_1).encode(Encoding::UTF_8)
            when Encoding::ISO_8859_1, Encoding::US_ASCII;  value.encode(Encoding::UTF_8)
            else; value
          end
        end
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
