require "logstash/filters/base"
require "logstash/namespace"
require "geoip"

# Add GeoIP fields from Maxmind database
class LogStash::Filters::GeoIP < LogStash::Filters::Base
  config_name "geoip"
  plugin_status "experimental"

  # GeoIP filter, adds information about geographical location of IP addresses.
  # This filter uses Maxmind GeoIP databases, have a look at https://www.maxmind.com/app/geolite

  # GeoIP database file to use, Country, City, ASN, ISP and organization databases are supported
  config :database, :validate => :string, :required => true

  # The field containing IP address, hostname is also OK. If this filed is an array, the first value will be used.
  config :ip_field, :validate => :string, :default => "IP"


  public
  def register
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
      ip = event[@ip_field]
      ip = ip.first if ip.is_a? Array
      geo_data = @geoip.send(@geoip_type, ip)
    rescue SocketError => e
      @logger.error("IP Field contained invalid IP address or hostname", :ip_field => @ip_field, :event => event)
    rescue Exception => e
      @logger.error("Uknown error while looking up GeoIP data", :exception => e, :ip_field => @ip_field, :event => event)
    end
    unless geo_data.nil?
      geo_data_hash = geo_data.to_hash
      geo_data_hash.delete(:request)
      if event["geoip"].is_a?(Hash)
        event["geoip"].merge!(geo_data_hash)
      else
        event["geoip"] = geo_data_hash
      end
      filter_matched(event)
    end
  end # def filter
end # class LogStash::Filters::GeoIP
