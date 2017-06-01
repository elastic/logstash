# encoding: utf-8
require "spec_helper"

require "sinatra"
require "logstash/api/modules/node_stats"
require "logstash/json"

describe LogStash::Api::Modules::NodeStats do
  include_context "api setup"
  include_examples "not found"

  extend ResourceDSLMethods

  # DSL describing response structure
  root_structure = {
    "jvm"=>{
      "uptime_in_millis" => Numeric,
      "threads"=>{
        "count"=>Numeric,
        "peak_count"=>Numeric
      },
      "gc" => {
        "collectors" => {
          "young" => {
            "collection_count" => Numeric,
            "collection_time_in_millis" => Numeric
          },
          "old" => {
            "collection_count" => Numeric,
            "collection_time_in_millis" => Numeric
          }
        }
      },
      "mem" => {
        "heap_used_in_bytes" => Numeric,
        "heap_used_percent" => Numeric,
        "heap_committed_in_bytes" => Numeric,
        "heap_max_in_bytes" => Numeric,
        "non_heap_used_in_bytes" => Numeric,
        "non_heap_committed_in_bytes" => Numeric,
        "pools" => {
          "survivor" => {
            "peak_used_in_bytes" => Numeric,
            "used_in_bytes" => Numeric,
            "peak_max_in_bytes" => Numeric,
            "max_in_bytes" => Numeric
          },
          "old" => {
            "peak_used_in_bytes" => Numeric,
            "used_in_bytes" => Numeric,
            "peak_max_in_bytes" => Numeric,
            "max_in_bytes" => Numeric
          },
          "young" => {
            "peak_used_in_bytes" => Numeric,
            "used_in_bytes" => Numeric,
            "peak_max_in_bytes" => Numeric,
            "max_in_bytes" => Numeric
          }
        }
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
        "percent"=>Numeric,
        "load_average" => { "1m" => Numeric }
      }
    },
   "pipelines" => {
     "main" => {
       "events" => {
         "duration_in_millis" => Numeric,
         "in" => Numeric,
         "filtered" => Numeric,
         "out" => Numeric,
         "queue_push_duration_in_millis" => Numeric
       }
     }
   },
   "reloads" => {
     "successes" => Numeric,
     "failures" => Numeric
   }
  }

  test_api_and_resources(root_structure)
end
