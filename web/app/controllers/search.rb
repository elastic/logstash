
$: << ".."
require "lib/net/clients/search"
require "timeout"

class Search < Application

  def index
    render
  end

  def query
    params[:offset] = (params[:offset] ? params[:offset].to_i : 0) rescue 0
    params[:limit] = (params[:limit] ? params[:limit].to_i : 100) rescue 100
    params[:log_type] = (params[:log_type] or "linux-syslog")

    params[:query] = params[:q]

    Timeout.timeout(10) do 
      @hits, @results = $search.search(params)
      render
    end
  end

  def graphpoints
    provides :json
    params[:log_type] = (params[:log_type] or "linux-syslog")
    orig_query = params[:q]

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

      hits = $search.searchhits(params[:log_type], queries.keys)
      #puts queries.inspect
      hits.each do |key,count|
        #puts "query: #{queries.has_key?(key)} / #{key} "
        queries[key][:hits] = count
      end

      @data = Hash.new
      queries.each do |query, entry|
        @data[entry[:time].to_i * 1000] = entry[:hits]
      end
      @data = @data.to_a
      render
    end
  end
end
