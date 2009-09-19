
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
    @searchclient = SearchClient.new(host="localhost", port=61613)
    msg = LogStash::Net::Messages::SearchHitsRequest.new
    msg.log_type = (params[:log_type] or "linux-syslog")
    msg.query = params[:q]
    @searchclient.sendmsg("/queue/logstash", msg)

    msg = LogStash::Net::Messages::SearchRequest.new
    msg.log_type = (params[:log_type] or "linux-syslog")
    msg.query = params[:q]
    msg.limit = 20
    @searchclient.sendmsg("/queue/logstash", msg)

    Timeout.timeout(10) do 
      @searchclient.run
      render
    end
  end
  
end
