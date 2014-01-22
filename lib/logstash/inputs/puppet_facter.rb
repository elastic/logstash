# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "json"

# Connects to a puppet server and requests facts
class LogStash::Inputs::PuppetFacter < LogStash::Inputs::Base
  config_name "puppet_facter"
  milestone 1

  #Remote IP Address to connect to
  config :host, :validate => :string, :default => "0.0.0.0"

  #Remote port to connect to
  config :port, :validate => :number, :default => 8140

  #Poll Interval in seconds
  config :interval, :validate => :number, :default => 600

  #Puppet environment
  config :environment, :validate => :string, :default => "production"

  #SSL Enabled?
  config :ssl, :validate => :boolean, :default => true

  #SSL Public Key
  config :public_key, :validate => :path

  #SSL Private Key
  config :private_key, :validate => :path

  def initialize(*args)
    super(*args)
  end # def initialize

  def register()
    if @ssl
      require "net/https"
      begin
        @pub = File.read(@public_key)
        @priv = File.read(@private_key)
      rescue
        logger.error("Unable to open keys.  Public key " + @public_key + ", private key " + @private_key)
        raise
      end
    else
      require "net/http"
    end
  end

  def run(output_queue)
    while true
      startTime = Time.now
      if @ssl
        http = Net::HTTP.new(@host, @port)
        http.use_ssl = true
        http.cert = OpenSSL::X509::Certificate.new(@pub)
        http.key = OpenSSL::PKey::RSA.new(@priv)
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      else
        http = Net::HTTP.new(@host, @port)
      end
      uri = "/" + @environment + "/certificate_statuses/no_key"
      begin
        request = Net::HTTP::Get.new(uri)
        response = http.request(request)
      rescue
        logger.error("Unable to retrieve from host " + @host + " port " + @port.to_s() + " at uri " + uri)
        raise
      end
      begin
        data = JSON.parse(response.body)
      rescue
        logger.error("Unable to parse cert status response")
        raise
      end
      hostList = []
      for item in data
        hostList.push(item["name"])
      end
      for host in hostList
        uri = "/" + @environment + "/facts/" + host
        begin
          request = Net::HTTP::Get.new(uri)
          response = http.request(request)
        rescue
          logger.warn("Unable to retrieve from host " + @host + " port " + @port.to_s() + " at uri " + uri)
          next
        end
        begin
          data = JSON.parse(response.body)["values"]
        rescue
          logger.warn("Unable to parse response from facts for node " + host)
          next
        end
        for key, value in data
          event = LogStash::Event.new("host" => host)
          event["fact_name"] = key
          event["fact_value"] = value
          decorate(event)
          output_queue << event
        end
      end
      endTime = Time.now
      diffTime = endTime - startTime
      waitTime = @interval - diffTime
      if waitTime > 0
        sleep(@interval)
        logger.debug("Sleeping for " + @waitTime)
      else
        logger.warn("Took longer than " + @interval.to_s() + " to process puppetmaster " + @host + " on port " + @port.to_s() + " with env " + @environment)
      end
    end
  end
end
