
$: << ".."
require "lib/net/clients/search"
require "timeout"

class Search < Application

  def index
    render
  end

  def query
    params[:offset] = (params[:offset] ? params[:offset].to_i : 0) rescue 0
    params[:limit] = (params[:limit] ? params[:limit].to_i : 20) rescue 20
    params[:log_type] = (params[:log_type] or "linux-syslog")

    @search = LogStash::Net::Clients::Search.new("/opt/logstash/etc/logstashd.yaml")
    params[:query] = params[:q]

    Timeout.timeout(10) do 
      @hits, @results = @search.search(params)
      #@search.run
      render
    end
  end
end
