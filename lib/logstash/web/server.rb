#!/usr/bin/env ruby
##rackup -Ilib:../lib -s thin

$:.unshift("%s/../lib" % File.dirname(__FILE__))
$:.unshift(File.dirname(__FILE__))

require "rubygems"
require "json"
require "eventmachine"
require "rack"
require "sinatra/async"
require "lib/elasticsearch"
require "logstash/namespace"

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
  end

  aget '/' do
    redirect "/search"
  end # '/'

  aget '/search' do
    headers({"Content-Type" => "text/html" })
    if params[:q] and params[:q] != ""
      elasticsearch.search(params) do |@results|
        @hits = (@results["hits"]["hits"] rescue [])
        body haml :"search/results", :layout => !request.xhr?
      end
    else
      @hits = []
      body haml :"search/results", :layout => !request.xhr?
    end
  end

  apost '/search/ajax' do
    headers({"Content-Type" => "text/html" })
    count = params["count"] = (params["count"] or 50).to_i
    offset = params["offset"] = (params["offset"] or 0).to_i
    elasticsearch.search(params) do |@results|
      @hits = (@results["hits"]["hits"] rescue [])
      @total = (@results["hits"]["total"] rescue 0)
      @graphpoints = []
      @results["facets"]["by_hour"]["entries"].each do |entry|
        @graphpoints << [entry["key"], entry["count"]]
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

end # class LogStashWeb

Rack::Handler::Thin.run(
  Rack::CommonLogger.new( \
    Rack::ShowExceptions.new( \
      LogStash::Web::Server.new)),
  :Port => 9292)
