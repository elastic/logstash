# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "logstash/api/modules/node_stats"
require "logstash/json"

describe LogStash::Api::Modules::NodeStats do
  include Rack::Test::Methods
  extend ResourceDSLMethods

  def app() # Used by Rack::Test::Methods
    described_class
  end

  # DSL describing response structure
  root_structure = {
    "events"=>{
      "in"=>Numeric,
      "filtered"=>Numeric,
      "out"=>Numeric
    },
    "jvm"=>{
      "threads"=>{
        "count"=>Numeric,
        "peak_count"=>Numeric
      }
    },
    "process"=>{
      "peak_open_file_descriptors"=>Numeric,
      "max_file_descriptors"=>Numeric,
      "open_file_descriptors"=>Numeric,
      "mem"=>{
        "total_virtual_in_bytes"=>Numeric
      },
      "cpu"=>{
        "total_in_millis"=>Numeric,
        "percent"=>Numeric
      }
    }
  }

  test_api_and_resources(root_structure)
end
