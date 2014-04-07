# coding: utf-8
require "test_utils"
require "socket"
require "json"
require "http"

describe "inputs/http" do
  extend LogStash::RSpec

  describe "basic input configuration" do
    config <<-CONFIG
      input {
        http {

        }
      }
    CONFIG

    input do |pipeline,queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      request_body = JSON.generate({ :message => "Hello Aafke" })
      content_length = request_body.length

      HTTP.post "http://localhost:8000/",
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

  describe "custom configuration with plain codec" do
    config <<-CONFIG
    input {
      http {
        codec => "plain"
      }
    }
    CONFIG

    input do |pipeline,queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      request_body = "Hello Aafke"
      content_length = request_body.length

      HTTP.post "http://localhost:8000/",
        :body => request_body,
        :headers => {
          "Content-Length" => content_length,
          "Content-Type" => "text/plain"
        }

      event = queue.pop

      insist { event } != nil
      insist { event["message"] } == "Hello Aafke"
    end
  end
end
