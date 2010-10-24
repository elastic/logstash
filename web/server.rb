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

class EventMachine::ConnectionError < RuntimeError; end

class LogStashWeb < Sinatra::Base
  register Sinatra::Async

  aget '/search' do
    http = EventMachine::HttpRequest.new("http://localhost:9200/_search")
    esreq = {
      "query" => {
        "query_string" => { 
           "query" => params[:q]
        }
      }
    }
    req = http.get :body => esreq.to_json
    req.callback do
      headers req.response_header
      data = JSON.parse(req.response)
      @hits = data["hits"]["hits"]
      body erb :search
    end
    req.errback do 
      body "Failed."
    end
  end
end

Rack::Handler::Thin.run(
  Rack::CommonLogger.new( \
    Rack::ShowExceptions.new( \
      LogStashWeb.new)),
  :Port => 9292)
