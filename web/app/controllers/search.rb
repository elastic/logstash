
$: << ".."
require "lib/net/client"
require "lib/net/messages/search"
require "lib/net/messages/searchhits"
require "lib/net/messages/ping"
require "timeout"

class SearchClient < LogStash::Net::MessageClient
  attr_reader :results
  attr_reader :hits

  def SearchHitsResponseHandler(msg)
    @hits = msg.hits
  end

  def SearchResponseHandler(msg)
    if @results == nil
      @results = []
    end

    msg.results.each do |result|
      @results << result
    end

    if msg.finished
      close
    end
  end # def SearchResponseHandler
end # class SearchClient

class Search < Application

  def index
    render
  end

  def query
    params[:offset] = (params[:offset] ? params[:offset].to_i : 0) rescue 0
    params[:limit] = (params[:limit] ? params[:limit].to_i : 20) rescue 20
    params[:log_type] = (params[:log_type] or "linux-syslog")
    @searchclient = SearchClient.new(host="localhost", port=61613)
    msg = LogStash::Net::Messages::SearchHitsRequest.new
    msg.log_type = params[:log_type]
    msg.query = params[:q]
    @searchclient.sendmsg("/queue/logstash", msg)

    msg = LogStash::Net::Messages::SearchRequest.new
    msg.log_type = (params[:log_type] or "linux-syslog")
    msg.query = params[:q]
    msg.offset = params[:offset]
    msg.limit = params[:limit]
    @searchclient.sendmsg("/queue/logstash", msg)

    Timeout.timeout(10) do 
      @searchclient.run
      render
    end
  end
  
end
