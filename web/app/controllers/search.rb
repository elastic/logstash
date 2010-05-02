
$: << ".."
require "lib/net/clients/search"
require "timeout"
require "ap"
#require "elasticsearch"

class Search < Application
  def index
    render
  end

  def query
    q = {}
    params[:log_type] = (params[:log_type] or "linux-syslog")
    params[:offset] = (params[:offset] ? params[:offset].to_i : 0) rescue 0
    params[:limit] = (params[:limit] ? params[:limit].to_i : 100) rescue 100

    options = {}
    options[:from] = params[:offset]
    options[:size] = params[:limit]
    options[:sort] = [ "@DATE" ]
    q[:query_string] = {
      :default_field => "@LINE",
      :query => params[:q],
    }

    options[:query] = q

    search = LogStash::Net::Clients::ElasticSearch.new("/opt/logstash/etc/logstashd.yaml")

    Timeout.timeout(10) do 
      results = search.query(options)
      @hits = results.hits
      @results = results.results
      @graphdata = _graphpoints(search, q)
      render
    end
  end

  def _graphpoints(search, query)
    #provides :json
    orig_query = query[:q]

    day = 60 * 60 * 24
    hour = 60 * 60

    starttime = (Time.now - day).to_i # + Time.now.gmt_offset
    starttime = starttime - (starttime % hour)
    increment = (params[:graphstep] or 60 * 60).to_i
    curtime = starttime
    @points = []
    # correct for timezone date offset
    Timeout.timeout(20) do 
      queries = []
      while starttime + day + 3600 > curtime
        endtime = curtime + increment - 1
        querygen = [query.clone]
        querygen << { 
          :range => {
            "@DATE" => {
              :to => endtime,
              :from => curtime,
            }
          }
        }
        queries << { :bool => { :must => querygen } }
        curtime += increment
      end

      @data = Hash.new
      queries.each do |genquery|
        count = search.count(genquery)
        puts count
        p genquery
        @data[genquery[:bool][:must][1][:range]["@DATE"][:from].to_i * 1000] = count
      end
      @data = @data.to_a
    end
    return @data
  end
end
