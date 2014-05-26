require "test_utils"
require "logstash/inputs/elasticsearch"

describe "inputs/elasticsearch" do
  extend LogStash::RSpec

  search_response = <<-RESPONSE
    {
      "_scroll_id":"xxx",
      "took":5,
      "timed_out":false,
      "_shards":{"total":15,"successful":15,"failed":0},
      "hits":{
        "total":1000050,
        "max_score":1.0,
        "hits":[
          {
            "_index":"logstash2",
            "_type":"logs",
            "_id":"AmaqL7VuSWKF-F6N_Gz72g",
            "_score":1.0,
            "_source" : {
              "message":"foobar",
              "@version":"1",
              "@timestamp":"2014-05-19T21:08:39.000Z",
              "host":"colin-mbp13r"
            }
          }
        ]
      }
    }
  RESPONSE

  scroll_response = <<-RESPONSE
    {
      "hits":{
        "hits":[]
      }
    }
  RESPONSE

  config <<-CONFIG
    input {
      elasticsearch {
        host => "localhost"
        scan => false
      }
    }
  CONFIG

  it "should retrieve json event from elasticseach" do
    # I somewhat duplicated our "input" rspec extension because I needed to add mocks for the the actual ES calls
    # and rspec expectations need to be in "it" statement but the "input" extension defines the "it"
    # TODO(colin) see how we can improve our rspec extension to better integrate in these scenarios

    expect_any_instance_of(LogStash::Inputs::Elasticsearch).to receive(:execute_search_request).and_return(search_response)
    expect_any_instance_of(LogStash::Inputs::Elasticsearch).to receive(:execute_scroll_request).with(any_args).and_return(scroll_response)

    pipeline = LogStash::Pipeline.new(config)
    queue = Queue.new
    pipeline.instance_eval do
      @output_func = lambda { |event| queue << event }
    end
    pipeline_thread = Thread.new { pipeline.run }
    event = queue.pop

    insist { event["message"] } == "foobar"

    # do not call pipeline.shutdown here, as it will stop the plugin execution randomly
    # and maybe kill input before calling execute_scroll_request.
    # TODO(colin) we should rework the pipeliene shutdown to allow a soft/clean shutdown mecanism,
    # using a shutdown event which can be fed into each plugin queue and when the plugin sees it
    # exits after completing its processing.
    #
    # pipeline.shutdown
    #
    # instead, since our scroll_response will terminate the plugin, we can just join the pipeline thread
    pipeline_thread.join
  end
end
