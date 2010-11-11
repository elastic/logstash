#!/usr/bin/env ruby
##rackup -Ilib:../lib -s thin

require "rubygems"
require "json"
require "eventmachine"
require "em-http-request"
require "rack"
require "sinatra/async"
#require "haml"
require "erb"
#require"sass/plugin/rack"

class EventMachine::ConnectionError < RuntimeError; end

class LogStashWeb < Sinatra::Base
  register Sinatra::Async
  set :haml, :format => :html5
  set :logging, true
  set :public, "./public"

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
      search :results
    else
      @hits = []
      body haml :"search/results"
    end
  end

  apost '/search/ajax' do
    headers({"Content-Type" => "text/html" })
    search :ajax
  end

  def search(type)
    http = EventMachine::HttpRequest.new("http://localhost:9200/_search")
    params[:offset] ||= 0
    params[:count] ||= 20

    puts "Query: #{params[:q]}"
    esreq = {
      "sort" => [
        { "@timestamp" => "desc" }
      ],
      "query" => {
        "query_string" => { 
           "query" => params[:q]
        }
      },
      "from" => params[:offset],
      "size" => params[:count],
    }
    req = http.get :body => esreq.to_json
    req.callback do
      #headers req.response_header
      data = JSON.parse(req.response)
      if req.response_header.status != 200
        @error = data["error"]
      end
      @hits = data["hits"]["hits"] rescue []
      body haml :"search/#{type.to_s}", :layout => !request.xhr?
    end
    req.errback do 
      body "Failed. #{req.response}"
    end
  end # def search
end # class LogStashWeb

      #Sass::Plugin::Rack.new( \
Rack::Handler::Thin.run(
  Rack::CommonLogger.new( \
    Rack::ShowExceptions.new( \
      LogStashWeb.new)),
  :Port => 9292)
