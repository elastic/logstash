require "test_utils"
require "gmetric"
require "socket"

describe "inputs/ganglia" do
  extend LogStash::RSpec

  describe "read gmetric_ganglia_packets" do
    port = 8649
    host = "127.0.0.1"
    config <<-CONFIG
      input {
        ganglia {
          port => #{port}
          host => "#{host}"
          type => "ganglion"
        }
      }
    CONFIG

    # 
    canned = [
        {:hostname => "contoso.com" , :name => "pageviews", :units => "req/min", :type => "int32", :value => 7000, :tmax => 60, :dmax => 300, :group => "test"},
        {:hostname => "contoso.com" , :name => "jvm.metrics.memNonHeapUsedM", :type => "float", :value => 1, :tmax => 60, :dmax => 0, :slope => "both" , :group => "jvm"}
        ]
    expected = [
        {"log_host"=>"contoso.com", "name"=>"pageviews", "val"=>"7000", "dmax"=>300, "tmax"=>60, "slope"=>"both", "units"=>"req/min", "vtype"=>"int32", "type"=> "ganglion", "host"=>"127.0.0.1"},
        {"log_host"=>"contoso.com", "name"=>"jvm.metrics.memNonHeapUsedM", "val"=>"1", "dmax"=>0, "tmax"=>60, "slope"=>"both", "units"=>"", "vtype"=>"float", "type"=> "ganglion", "host"=>"127.0.0.1"}
        ]

   
    input do |pipeline, queue|
      # Start the pipeline
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      # Take each of canned hashes and send a metric
      canned.each do |params|
        Ganglia::GMetric.send(host,port,params)
      end
 
      # Compare with the fields we care out to prove they went through the system
      events = expected.length.times.collect { queue.pop }
      # TODO(Ludovicus): Figure out how to do pop with timeout.  pop(true) is not good enough. Stud.try?
      insist { events.length } == expected.length
      events.length.times do |i|
        puts(events[i].to_hash)
        puts(expected[i])
        expected[i].each do |key,val|
            insist { events[i][key] } == val
        end
      end
      
    end # input
  end
  
    describe "read hadoop_ganglia_packets" do
    port = 8650
    host = "127.0.0.1"
    config <<-CONFIG
      input {
        ganglia {
          port => #{port}
          host => "#{host}"
          type => "o-negative"
        }
      }
    CONFIG

    # 
    canned = [
        # Metadata for ugi.ugi.loginSuccess_num_ops
        "000000800000001f75732d776573742d322e636f6d707574652e616d617a6f6e6177732e636f6d000000001c7567692e7567692e6c6f67696e537563636573735f6e756d5f6f70730000000000000005666c6f61740000000000001c7567692e7567692e6c6f67696e537563636573735f6e756d5f6f707300000000000000010000003c00000000000000010000000547524f5550000000000000077567692e75676900",
        # Data Packet for ugi. ugi.loginSuccess_num_ops
        "000000850000001f75732d776573742d322e636f6d707574652e616d617a6f6e6177732e636f6d000000001c7567692e7567692e6c6f67696e537563636573735f6e756d5f6f70730000000000000002257300000000000139000000",
        # Metadata for jvm.metrics.memNonHeapUsedM
        "000000800000001f75732d776573742d322e636f6d707574652e616d617a6f6e6177732e636f6d000000001b6a766d2e6d6574726963732e6d656d4e6f6e48656170557365644d000000000000000005666c6f61740000000000001b6a766d2e6d6574726963732e6d656d4e6f6e48656170557365644d0000000000000000030000003c00000000000000010000000547524f55500000000000000b6a766d2e6d65747269637300",
        # Data Packet for jvm.metrics.memNonHeapUsedM
        "000000850000001f75732d776573742d322e636f6d707574652e616d617a6f6e6177732e636f6d000000001b6a766d2e6d6574726963732e6d656d4e6f6e48656170557365644d000000000000000002257300000000000932322e393336363135000000",
        # Data Packet for jvm.metrics.memNonHeapCommittedM
        "000000850000001f75732d776573742d322e636f6d707574652e616d617a6f6e6177732e636f6d00000000206a766d2e6d6574726963732e6d656d4e6f6e48656170436f6d6d69747465644d0000000000000002257300000000000533392e3735000000",
        ]
    expected = [
        {"log_host"=>"us-west-2.compute.amazonaws.com", "name"=>"ugi.ugi.loginSuccess_num_ops", "val"=>"9", "dmax"=>0, "tmax"=>60, "slope"=>"positive", "units"=>"", "vtype"=>"float", "type"=> "o-negative", "host"=>"127.0.0.1" },
        {"log_host"=>"us-west-2.compute.amazonaws.com", "name"=>"jvm.metrics.memNonHeapUsedM", "val"=>"22.936615", "dmax"=>0, "tmax"=>60, "slope"=>"both", "units"=>"", "vtype"=>"float", "type"=> "o-negative", "host"=>"127.0.0.1"}
        ]

   
    input do |pipeline, queue|
      # Start the pipeline
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      # Create a UDP socket and connect it to the rendezvous host:port
      socket = Stud.try(5.times) { UDPSocket.new(Socket::AF_INET) }
      socket.connect(host, port)

      # Take each of the horrid hex strings, convert to binary and send it to the ganglia input
      canned.each do |hexystr|
        binpkt = [ hexystr ].pack("H*")
        socket.send(binpkt,0)
      end
      socket.close
 
      # Though we sent 5 packets, we expect the metadata to be absorbed and the one data packet sans metadata to disappear
      # Compare with the fields we care out to prove they went through the system
      events = expected.length.times.collect { queue.pop }
      insist { events.length } == expected.length
      events.length.times do |i|
        puts(events[i].to_hash)
        expected[i].each do |key,val|
            insist { events[i][key] } == val
        end
      end
      # TODO(Ludovicus): How can we check there are no remaining packets on the queue?
    end # input
  end
end


