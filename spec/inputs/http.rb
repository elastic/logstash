# coding: utf-8
require "test_utils"
require "socket"
require "json"
require "http"
require "webrick"
require 'logstash/inputs/http'

describe "inputs/http" do
  extend LogStash::RSpec

  describe "basic input configuration for push" do
    config <<-CONFIG
      input {
        http {
          port => 8003
        }
      }
    CONFIG

    input do |pipeline,queue|
      Thread.new { pipeline.run }
      sleep 0.1 while not pipeline.ready?

      request_body = JSON.generate({ :message => "Hello Aafke" })
      content_length = request_body.length

      HTTP.post "http://localhost:8003/",
        :body => request_body,
        :headers => {
          "Content-Length" => content_length,
          "Content-Type" => "application/json"
        }

      event = queue.pop

      insist { event } != nil
      insist { event["message"] } == "Hello Aafke"
    end
  end

  describe "basic input configuration for pull" do
    begin
      port = 8002

      options =  { :Port => port }

      # Start a basic HTTP server to receive logging information.
      http_server = WEBrick::HTTPServer.new options
      http_server.mount_proc '/status' do |req,res|
        response_body = "{ \"message\": \"Hello world\" }"

        res.status = 200
        res.body = response_body
      end

      server_thread = Thread.new { http_server.start }

      config = {
        "url" => "http://localhost:#{port}/status",
        "interval" => 1000,
        "mode" => 'client'
      }

      input = LogStash::Inputs::Http.new config
      input.register

      event = input.pull_event

      insist { event } != nil
      insist { event['message'] } == 'Hello world'
    ensure
      http_server.shutdown
    end
  end
end
