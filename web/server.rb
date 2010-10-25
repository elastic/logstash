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
require "ap"
#require"sass/plugin/rack"

class EventMachine::ConnectionError < RuntimeError; end

class LogStashWeb < Sinatra::Base
  register Sinatra::Async
  set :haml, :format => :html5
  set :logging, true

  aget '/style.css' do
    headers "Content-Type" => "text/css; charset=utf8"
    body sass :style
  end

  aget '/' do
    body haml :"main/index"
  end # '/'

  aget '/search' do
    http = EventMachine::HttpRequest.new("http://localhost:9200/_search")
    esreq = {
      "sort" => [
        { "received_timestamp" => "desc" }
      ],
      "query" => {
        "query_string" => { 
           "query" => params[:q]
        }
      },
    }
    req = http.get :body => esreq.to_json
    req.callback do
      headers req.response_header
      data = JSON.parse(req.response)
      p data
      @hits = data["hits"]["hits"] rescue []
      body haml :"search/results"
    end
    req.errback do 
      body "Failed."
    end
  end # '/search'
end

      #Sass::Plugin::Rack.new( \
Rack::Handler::Thin.run(
  Rack::CommonLogger.new( \
    Rack::ShowExceptions.new( \
      LogStashWeb.new)),
  :Port => 9292)
