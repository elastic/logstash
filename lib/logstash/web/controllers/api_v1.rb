require "logstash/search/elasticsearch"
require "logstash/search/query"
require "logstash/web/helpers/require_param"
require "sinatra/base" # gem sinatra

class LogStash::Web::Server < Sinatra::Base

  # TODO(sissel): move this to a lib?
  # Or a LogStash::Search::WebHelper or something?
  def api_search
    count = params["count"] = (params["count"] or 50).to_i
    offset = params["offset"] = (params["offset"] or 0).to_i
    format = (params[:format] or "json")

    query = LogStash::Search::Query.new(
      :query_string => params[:q],
      :offset => offset,
      :count => count
    )

    @backend.search(query, async=false) do |results|
      @results = results
      if @results.error?
        status 500
        case format
        when "html"
          content_type :html
          body haml :"search/error", :layout => !request.xhr?
        when "text"
          content_type :txt
          body erb :"search/error.txt", :layout => false
        when "txt"
          content_type :txt
          body erb :"search/error.txt", :layout => false
        when "json"
          content_type :json
          # TODO(sissel): issue/30 - needs refactoring here.
          body({ "error" => @results.error_message }.to_json)
        end # case params[:format]
        next
      end

      @events = @results.events
      @total = (@results.total rescue 0)
      count = @results.events.size

      if count and offset
        if @total > (count + offset)
          @result_end = (count + offset)
        else
          @result_end = @total
        end
        @result_start = offset
      end

      if count + offset < @total
        next_params = params.clone
        next_params["offset"] = [offset + count, @total - count].min
        @next_href = "?" +  next_params.collect { |k,v| [URI.escape(k.to_s), URI.escape(v.to_s)].join("=") }.join("&")
        last_params = next_params.clone
        last_params["offset"] = @total - count
        @last_href = "?" +  last_params.collect { |k,v| [URI.escape(k.to_s), URI.escape(v.to_s)].join("=") }.join("&")
      end

      if offset > 0
        prev_params = params.clone
        prev_params["offset"] = [offset - count, 0].max
        @prev_href = "?" +  prev_params.collect { |k,v| [URI.escape(k.to_s), URI.escape(v.to_s)].join("=") }.join("&")

        #if prev_params["offset"] > 0
          first_params = prev_params.clone
          first_params["offset"] = 0
          @first_href = "?" +  first_params.collect { |k,v| [URI.escape(k.to_s), URI.escape(v.to_s)].join("=") }.join("&")
        #end
      end

      # TODO(sissel): make a helper function taht goes hash -> cgi querystring
      @refresh_href = "?" +  params.collect { |k,v| [URI.escape(k.to_s), URI.escape(v.to_s)].join("=") }.join("&")

      case format
      when "html"
        content_type :html
        body haml :"search/ajax", :layout => !request.xhr?
      when "text"
        content_type :txt
        body erb :"search/results.txt", :layout => false
      when "txt"
        content_type :txt
        body erb :"search/results.txt", :layout => false
      when "json"
        content_type :json
        pretty = params.has_key?("pretty")
        if pretty
          body JSON.pretty_generate(@results.to_hash)
        else
          body @results.to_json
        end
      end # case params[:format]
    end # @backend.search
  end # def api_search

  # TODO(sissel): Update these to all be /api/v1
  post '/api/search' do
    api_search
  end # post /api/search

  get '/api/search' do
    api_search
  end # get /api/search

  get '/api/histogram' do
    missing = require_param(:q)
    if !missing.empty?
      status 500
      body({ "error" => "Missing requiremed parameters",
             "missing" => missing }.to_json)
      next
    end # if !missing.empty?

    format = (params[:format] or "json")            # default json
    field = (params[:field] or "@timestamp")        # default @timestamp
    interval = (params[:interval] or 3600000).to_i  # default 1 hour

    results = @backend.histogram(params[:q], field, interval, async=false)

    p :results => results
    if results.error?
      status 500
      body({ "error" => results.error_message }.to_json)
      next
    end

    begin
      json = results.results.to_json
      p :json => json
      content_type :json
      status 200
      body json
    rescue => e
      p :exception => e
      p e
      raise e
    end
  end # get '/api/histogram'
end # class LogStash::Web::Server
