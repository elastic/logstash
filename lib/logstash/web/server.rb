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
    params[:count] = (params[:count] or 50).to_i
    params[:offset] = (params[:offset] or 0).to_i
    elasticsearch.search(params) do |@results|
      @hits = (@results["hits"]["hits"] rescue [])
      @total = (@results["hits"]["total"] rescue 0)
      @graphpoints = []
      @results["facets"]["by_hour"]["entries"].each do |entry|
        @graphpoints << [entry["key"], entry["count"]]
      end

      if params[:count] and params[:offset]
        if @total > (params[:count] + params[:offset])
          @result_end = params[:count] + params[:offset]
        else 
          @result_end = @total
        end
        @result_start = params[:offset]
      end
      body haml :"search/ajax", :layout => !request.xhr?
    end
  end

end # class LogStashWeb

Rack::Handler::Thin.run(
  Rack::CommonLogger.new( \
    Rack::ShowExceptions.new( \
      LogStash::Web::Server.new)),
  :Port => 9292)
