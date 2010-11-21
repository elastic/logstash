
require "em-http-request"
require "logstash/namespace"
require "logstash/logging"
require "logstash/event"

module LogStash::Web; end
class LogStash::Web::ElasticSearch
  def initialize
    @logger = LogStash::Logger.new(STDOUT)
  end

  def search(params)
    http = EventMachine::HttpRequest.new("http://localhost:9200/_search")
    params[:offset] ||= 0
    params[:count] ||= 20

    @logger.info(["Query", params])
    esreq = {
      "sort" => [
        { "@timestamp" => "desc" }
      ],
      "query" => {
        "query_string" => { 
           "query" => params[:q],
           "default_operator" => "AND"
        } # query_string
      }, # query
      "facets" => {
        "by_hour" => { 
          "histogram" => {
            "field" => "@timestamp",
            "time_interval" => "1h",
          }, # histogram
        }, # by_hour
      }, # facets
      "from" => params[:offset],
      "size" => params[:count],
    }
    #@logger.info(["ElasticSearch Query", esreq])
    start_time = Time.now
    req = http.get :body => esreq.to_json
    req.callback do
      #headers req.response_header
      data = JSON.parse(req.response)
      data["duration"] = Time.now - start_time

      # TODO(sissel): Plugin-ify this (Search filters!)
      #  Search anonymization
      #require "digest/md5"
      #data["hits"]["hits"].each do |hit|
      [].each do |hit|
        event = LogStash::Event.new(hit["_source"])
        event.to_hash.each do |key, value|
          next unless value.is_a?(String)
          value.gsub!(/[^ ]+\.loggly\.net/) { |match| "loggly-" + Digest::MD5.hexdigest(match)[0..6]  + ".example.com"}
        end

        event.fields.each do |key, value|
          value = [value] if value.is_a?(String)
          next unless value.is_a?(Array)
          value.each do |v|
            v.gsub!(/[^ ]+\.loggly\.net/) { |match| "loggly-" + Digest::MD5.hexdigest(match)[0..6]  + ".example.com"}
          end # value.each
        end # hit._source.@fields.each
      end # data.hits.hits.each

      @logger.info(["Got search results", 
                   { :query => params[:q], :duration => data["duration"]}])
      #@logger.info(data)
      if req.response_header.status != 200
        @error = data["error"]
      end
      yield data
    end
    req.errback do 
      @logger.warn(["Query failed", params, req.response])
      yield({ "error" => req.response })
    end
  end # def search
end
