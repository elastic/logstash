require "logstash/filters/base"
require "logstash/namespace"
require "tempfile"

# Add GeoIP fields from Maxmind database
#
# GeoIP filter, adds information about geographical location of IP addresses.
# This filter uses Maxmind GeoIP databases, have a look at
# https://www.maxmind.com/app/geolite
#
# Logstash releases ship with the GeoLiteCity database made available from
# Maxmind with a CCA-ShareAlike 3.0 license. For more details on geolite, see
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

  # The field containing IP address, hostname is also OK. If this field is an
  # array, only the first value will be used.
  config :source, :validate => :string

  # Array of geoip fields that we want to be included in our event.
  # 
  # Possible fields depend on the database type. By default, all geoip fields
  # are included in the event.
  #
  # For the built in GeoLiteCity database, the following are available:
  # city_name, continent_code, country_code2, country_code3, country_name,
  # dma_code, ip, latitude, longitude, postal_code, region_name, timezone
  config :fields, :validate => :array

  # Specify into what field you want the geoip data.
  # This can be useful for example if you have a src_ip and dst_ip and want
  # information of both IP's
  config :target, :validate => :string, :default => 'geoip'

  public
  def register
    require "geoip"
    if @database.nil?
      if __FILE__ =~ /^file:\/.+!.+/
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
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::GeoIP
