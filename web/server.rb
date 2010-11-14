#!/usr/bin/env ruby
##rackup -Ilib:../lib -s thin

$:.unshift("%s/../lib" % File.dirname(__FILE__))

require "rubygems"
require "json"
require "eventmachine"
require "rack"
require "sinatra/async"
require "lib/elasticsearch"

class EventMachine::ConnectionError < RuntimeError; end

class LogStashWeb < Sinatra::Base
  register Sinatra::Async
  set :haml, :format => :html5
  set :logging, true
  set :public, "./public"
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
    elasticsearch.search(params) do |@results|
      @hits = (@results["hits"]["hits"] rescue [])
      @facets = (@results["facets"] or {})
      body haml :"search/ajax", :layout => !request.xhr?
    end
  end

end # class LogStashWeb

Rack::Handler::Thin.run(
  Rack::CommonLogger.new( \
    Rack::ShowExceptions.new( \
      LogStashWeb.new)),
  :Port => 9292)
