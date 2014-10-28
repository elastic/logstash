require "spec_helper"
require "logstash/outputs/statsd"
require "mocha/api"
require "socket"

describe LogStash::Outputs::Statsd do
  
  port = 4399
  udp_server = UDPSocket.new
  udp_server.bind("127.0.0.1", port)

  describe "send metric to statsd" do
    config <<-CONFIG
      input {
        generator {
          message => "valid"
          count => 1
        }
      }

      output {
        statsd {
          host => "localhost"
          sender => "spec"
          port => #{port}
          count => [ "test.valid", "0.1" ]
        }
      }
    CONFIG

    agent do
      metric, *data = udp_server.recvfrom(100)
      insist { metric } == "logstash.spec.test.valid:0.1|c"
    end
  end

  describe "output a very small float" do
    config <<-CONFIG
      input {
        generator {
          message => "valid"
          count => 1
        }
      }

      output {
        statsd {
          host => "localhost"
          sender => "spec"
          port => #{port}
          count => [ "test.valid", 0.000001 ]
        }
      }
    CONFIG

    agent do
      metric, *data = udp_server.recvfrom(100)
      insist { metric } == "logstash.spec.test.valid:0.000001|c"
    end
  end

  describe "output a very big float" do
    config <<-CONFIG
      input {
        generator {
          message => "valid"
          count => 1
        }
      }

      output {
        statsd {
          host => "localhost"
          sender => "spec"
          port => #{port}
          count => [ "test.valid", 9999999999999.01 ]
        }
      }
    CONFIG

    agent do
      metric, *data = udp_server.recvfrom(100)
      insist { metric } == "logstash.spec.test.valid:9999999999999.01|c"
    end
  end
end
