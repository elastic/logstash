#!/usr/bin/env ruby
# I don't want folks to have to learn to use yet another tool (rackup)
# just to launch logstash-web. So let's work like a standard ruby
# executable.
##rackup -Ilib:../lib -s thin

$:.unshift("%s/../lib" % File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__))

require "logstash/search/elasticsearch"
require "logstash/search/query"
require "logstash/namespace"
require "logstash/web/helpers/require_param"
require "json" # gem json
require "rack" # gem rack
require "mizuno" # gem mizuno
require "sinatra/base" # gem sinatra

module LogStash::Web; end

class LogStash::Web::Server < Sinatra::Base
  #register Sinatra::Async
  helpers Sinatra::RequireParam # logstash/web/helpers/require_param

  set :haml, :format => :html5
  set :logging, true
  set :views, "#{File.dirname(__FILE__)}/views"

  use Rack::CommonLogger
  use Rack::ShowExceptions

  def initialize(settings={})
    super
    # TODO(sissel): Support alternate backends
    backend_url = URI.parse(settings.backend_url)

    case backend_url.scheme 
      when "elasticsearch"
        @backend = LogStash::Search::ElasticSearch.new(
          :host => backend_url.host,
          :port => backend_url.port
        )
      when "twitter"
        require "logstash/search/twitter"
        @backend = LogStash::Search::Twitter.new(
          :host => backend_url.host,
          :port => backend_url.port
        )
    end # backend_url.scheme
  end # def initialize
 
  # Mizuno can't serve static files from a jar
  # https://github.com/matadon/mizuno/issues/9
  #if __FILE__ =~ /^file:.+!.+$/
    get '/js/*' do static_file end
    get '/css/*' do static_file end
    get '/media/*' do static_file end
    get '/ws/*' do static_file end
  #else
    ## If here, we aren't running from a jar; safe to serve files
    ## through the normal public handler.
    #set :public, "#{File.dirname(__FILE__)}/public"
  #end

  def static_file
    # request.path_info is the full path of the request.
    path = File.join(File.dirname(__FILE__), "public", *request.path_info.split("/"))
    if File.exists?(path)
      ext = path.split(".").last
      case ext
        when "js"; headers "Content-Type" => "application/javascript"
        when "css"; headers "Content-Type" => "text/css"
        when "jpg"; headers "Content-Type" => "image/jpeg"
        when "jpeg"; headers "Content-Type" => "image/jpeg"
        when "png"; headers "Content-Type" => "image/png"
        when "gif"; headers "Content-Type" => "image/gif"
      end

      body File.new(path, "r").read
    end
  end # def static_file

  get '/style.css' do
    headers "Content-Type" => "text/css; charset=utf8"
    body sass :style
  end # /style.css

  get '/' do
    redirect "/search"
  end # '/'

  get '/search' do
    result_callback = proc do |results|
      status 500 if @error
      @results = results

      p :got => results

      params[:format] ||= "html"
      case params[:format]
      when "html"
        headers({"Content-Type" => "text/html" })
        body haml :"search/results", :layout => !request.xhr?
      when "text"
        headers({"Content-Type" => "text/plain" })
        body erb :"search/results.txt", :layout => false
      when "txt"
        headers({"Content-Type" => "text/plain" })
        body erb :"search/results.txt", :layout => false
      when "json"
        headers({"Content-Type" => "text/plain" })
        # TODO(sissel): issue/30 - needs refactoring here.
        hits = @hits.collect { |h| h["_source"] }
        response = {
          "hits" => hits,
        }

        response["error"] = @error if @error
        body response.to_json
      end # case params[:format]
    end # proc result_callback

    # We'll still do a search query here even though most users
    # have javascript enabled, we need to show the results in
    # case a user doesn't have javascript.
    if params[:q] and params[:q] != ""
      query = LogStash::Search::Query.new(
        :query_string => params[:q],
        :offset => params[:offset],
        :count => params[:count]
      )

      @backend.search(query) do |results|
        p :got => results
        begin
          result_callback.call results
        rescue => e
          p :exception => e
        end
      end # @backend.search
    else
      results = LogStash::Search::Result.new(
        :events => [],
        :error_message => "No query given"
      )
      result_callback.call results
    end
  end # get '/search'

  post '/api/search' do
    api_search
  end # post /api/search

  get '/api/search' do
    api_search
  end # get /api/search

  def api_search
    headers({"Content-Type" => "text/html" })
    count = params["count"] = (params["count"] or 50).to_i
    offset = params["offset"] = (params["offset"] or 0).to_i
    format = (params[:format] or "json")

    query = LogStash::Search::Query.new(
      :query_string => params[:q],
      :offset => offset,
      :count => count
    )

    @backend.search(query) do |results|
      @results = results
      if @results.error?
        status 500
        case format
        when "html"
          headers({"Content-Type" => "text/html" })
          body haml :"search/error", :layout => !request.xhr?
        when "text"
          headers({"Content-Type" => "text/plain" })
          body erb :"search/error.txt", :layout => false
        when "txt"
          headers({"Content-Type" => "text/plain" })
          body erb :"search/error.txt", :layout => false
        when "json"
          headers({"Content-Type" => "text/plain" })
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
        headers({"Content-Type" => "text/html" })
        body haml :"search/ajax", :layout => !request.xhr?
      when "text"
        headers({"Content-Type" => "text/plain" })
        body erb :"search/results.txt", :layout => false
      when "txt"
        headers({"Content-Type" => "text/plain" })
        body erb :"search/results.txt", :layout => false
      when "json"
        headers({"Content-Type" => "text/plain" })
        pretty = params.has_key?("pretty")
        if pretty
          body JSON.pretty_generate(@results.to_hash)
        else
          body @results.to_json
        end
      end # case params[:format]
    end # @backend.search
  end # def api_search

  get '/api/histogram' do
    headers({"Content-Type" => "text/plain" })
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
    @backend.histogram(params[:q], field, interval) do |results|
      @results = results
      if @results.error?
        status 500
        body({ "error" => @results.error_message }.to_json)
        next
      end

      begin
        a = results.results.to_json
      rescue => e
        status 500
        body e.inspect
        p :exception => e
        p e
        raise e
      end
      status 200
      body a
    end # @backend.search
  end # get '/api/histogram'

  get '/*' do
    status 404 if @error
    body "Invalid path."
  end # get /*
end # class LogStash::Web::Server

require "optparse"
Settings = Struct.new(:daemonize, :logfile, :address, :port, :backend_url)
settings = Settings.new

settings.address = "0.0.0.0"
settings.port = 9292
settings.backend_url = "elasticsearch://localhost:9200/"

progname = File.basename($0)

opts = OptionParser.new do |opts|
  opts.banner = "Usage: #{progname} [options]"

  opts.on("-d", "--daemonize", "Daemonize (default is run in foreground).") do
    settings.daemonize = true
  end

  opts.on("-l", "--log FILE", "Log to a given path. Default is stdout.") do |path|
    settings.logfile = path
  end

  opts.on("-a", "--address ADDRESS", "Address on which to start webserver. Default is 0.0.0.0.") do |address|
    settings.address = address
  end

  opts.on("-p", "--port PORT", "Port on which to start webserver. Default is 9292.") do |port|
    settings.port = port.to_i
  end

  opts.on("-b", "--backend URL",
          "The backend URL to use. Default is elasticserach://localhost:9200/") do |url|
    settings.backend_url = url
  end
end

opts.parse!

if settings.daemonize
  if Process.fork == nil
    Process.setsid
  else
    exit(0)
  end
end

if settings.logfile
  logfile = File.open(settings.logfile, "w")
  STDOUT.reopen(logfile)
  STDERR.reopen(logfile)
elsif settings.daemonize
  # Write to /dev/null if
  devnull = File.open("/dev/null", "w")
  STDOUT.reopen(devnull)
  STDERR.reopen(devnull)
end

#Rack::Handler::Thin.run(
Mizuno::HttpServer.run(
  #Rack::CommonLogger.new( \
    #Rack::ShowExceptions.new( \
      LogStash::Web::Server.new(settings),
  :Port => settings.port, :Host => settings.address)
