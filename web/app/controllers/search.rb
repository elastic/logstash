
#$: << ".."
#require "lib/net/clients/search"
require "timeout"
require "elasticsearch"

class Search < Application
  def index
    render
  end

  def query
    q = {}
    params[:log_type] = (params[:log_type] or "linux-syslog")
    params[:offset] = (params[:offset] ? params[:offset].to_i : 0) rescue 0
    params[:limit] = (params[:limit] ? params[:limit].to_i : 100) rescue 100

    q[:from] = params[:offset]
    q[:size] = params[:limit]
    q[:log_type] = params[:log_type]
    q[:base] = "logstash"
    q[:q] = params[:q]

    search = ElasticSearch.new("localhost:9200")

    Timeout.timeout(10) do 
      #@hits, @results = $search.search(params)
      results = search.query(q)
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

    starttime = (Time.now - day).to_i + Time.now.gmt_offset
    starttime = starttime - (starttime % hour)
    increment = 60 * 60
    curtime = starttime
    @points = []
    # correct for timezone date offset
    Timeout.timeout(20) do 
      queries = {}
      while starttime + day > curtime
        endtime = curtime + increment - 1
        querygen = "@DATE:[#{curtime} #{endtime}] AND (#{orig_query})"
        puts "Query: #{querygen}"
        queries[querygen] = {
          :time => curtime,
          :query => querygen,
        }
        curtime += increment
      end

      queries.each do |genquery, data|
        hitq = query.clone
        hitq[:q] = genquery
        count = search.count(hitq)
        queries[genquery][:hits] = count
      end

      @data = Hash.new
      queries.each do |query, entry|
        @data[entry[:time].to_i * 1000] = entry[:hits]
      end
      @data = @data.to_a
    end
    return @data
  end
end
