#!/usr/bin/env ruby
##rackup -Ilib:../lib -s thin

$:.unshift("%s/../lib" % File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__))

require "eventmachine"
require "json"
require "lib/elasticsearch"
require "logstash/namespace"
require "rack"
require "rubygems"
require "sinatra/async"

class EventMachine::ConnectionError < RuntimeError; end

class LogStash::Web::Server < Sinatra::Base
  register Sinatra::Async
  set :haml, :format => :html5
  set :logging, true
  set :public, "#{File.dirname(__FILE__)}/public"
  set :views, "#{File.dirname(__FILE__)}/views"
  elasticsearch = LogStash::Web::ElasticSearch.new

  aget '/style.css' do
    headers "Content-Type" => "text/css; charset=utf8"
    body sass :style
  end # /style.css

  aget '/' do
    redirect "/search"
  end # '/'

  aget '/search' do
    result_callback = proc do
      status 500 if @error

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
        hits = @hits.collect { |h| h["_source"] }
        response = {
          "hits" => hits,
          "facets" => (@results["facets"] rescue nil),
        }

        response["error"] = @error if @error
        body response.to_json
      end # case params[:format]
    end # proc result_callback

    # We'll still do a search query here even though most users
    # have javascript enabled, we need to show the results in
    # case a user doesn't have javascript.
    if params[:q] and params[:q] != ""
      elasticsearch.search(params) do |results|
        @results = results
        @hits = (@results["hits"]["hits"] rescue [])
        begin
          result_callback.call
        rescue => e
          puts e
        end
      end # elasticsearch.search
    else
      #@error = "No query given."
      @hits = []
      result_callback.call
    end
  end # aget '/search'

  apost '/search/ajax' do
    headers({"Content-Type" => "text/html" })
    count = params["count"] = (params["count"] or 50).to_i
    offset = params["offset"] = (params["offset"] or 0).to_i
    elasticsearch.search(params) do |results|
      @results = results
      if @results.include?("error")
        body haml :"search/error", :layout => !request.xhr?
        next
      end

      @hits = (@results["hits"]["hits"] rescue [])
      @total = (@results["hits"]["total"] rescue 0)
      @graphpoints = []
      begin
        @results["facets"]["by_hour"]["entries"].each do |entry|
          @graphpoints << [entry["key"], entry["count"]]
        end
      rescue => e
        puts e
      end

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
        last_params["offset"] = @total - offset
        @last_href = "?" +  last_params.collect { |k,v| [URI.escape(k.to_s), URI.escape(v.to_s)].join("=") }.join("&")
      end

      if offset > 0
        prev_params = params.clone
        prev_params["offset"] = [offset - count, 0].max
        @prev_href = "?" +  prev_params.collect { |k,v| [URI.escape(k.to_s), URI.escape(v.to_s)].join("=") }.join("&")

        if prev_params["offset"] > 0
          first_params = prev_params.clone
          first_params["offset"] = 0
          @first_href = "?" +  first_params.collect { |k,v| [URI.escape(k.to_s), URI.escape(v.to_s)].join("=") }.join("&")
        end
      end

      body haml :"search/ajax", :layout => !request.xhr?
    end # elasticsearch.search
  end # apost '/search/ajax'
end # class LogStash::Web::Server

require "optparse"
Settings = Struct.new(:daemonize, :logfile, :address, :port)
settings = Settings.new

settings.address      = "0.0.0.0"
settings.port      = 9292

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

Rack::Handler::Thin.run(
  Rack::CommonLogger.new( \
    Rack::ShowExceptions.new( \
      LogStash::Web::Server.new)),
  :Port => settings.port, :Host => settings.address)
