
require "em-http-request"
require "logstash/namespace"
require "logstash/logging"

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
      @logger.info(["Got search results", 
                   { :query => params[:q], :duration => data["duration"]}])
      @logger.info(data)
      if req.response_header.status != 200
        @error = data["error"]
      end
      yield data
    end
    req.errback do 
      @logger.warn(["Query failed", params, req.response])
      yield :failure
    end
  end # def search
end
