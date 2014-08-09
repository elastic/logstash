
require "test_utils"
require "gelf"
describe "inputs/gelf" do
  extend LogStash::RSpec

  describe "reads chunked gelf messages " do
    port = 12209
    host = "127.0.0.1"
    chunksize = 1420
    gelfclient = GELF::Notifier.new(host,port,chunksize)

    config <<-CONFIG
      input {
        gelf {
          port => "#{port}"
          host => "#{host}"
        }
      }
    CONFIG

    input do |pipeline, queue|
      Thread.new { pipeline.run }
      sleep 0.1 while !pipeline.ready?

      # generate random characters (message is zipped!) from printable ascii ( SPACE till ~ )
      # to trigger gelf chunking
      s = StringIO.new
      for i in 1..2000
        s << 32 + rand(126-32)
      end
      large_random = s.string

      [ "hello",
        "world",
        large_random,
        "we survived gelf!"
      ].each do |m|
  	    gelfclient.notify!( "short_message" => m )
        # poll at most 10 times
        waits = 0
        while waits < 10 and queue.size == 0
          sleep 0.1
          waits += 1
        end
        insist { queue.size } > 0
        insist { queue.pop["message"] } == m
      end

    end
  end
end
