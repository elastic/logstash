# encoding: utf-8
require "logstash/inputs/threadable"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Read from varnish cache's shared memory log
class LogStash::Inputs::Varnishlog < LogStash::Inputs::Threadable
  config_name "varnishlog"
  milestone 1

  public
  def register
    require 'varnish'
    @vd = Varnish::VSM.VSM_New
    Varnish::VSL.VSL_Setup(@vd)
    Varnish::VSL.VSL_Open(@vd, 1)

  end # def register

  def run(queue)
    @q = queue
    @hostname = Socket.gethostname
    Varnish::VSL.VSL_Dispatch(@vd, self.method(:cb).to_proc, FFI::MemoryPointer.new(:pointer))
  end # def run

  private
  def cb(priv, tag, fd, len, spec, ptr, bitmap)
    begin
      str = ptr.read_string(len)
      event = LogStash::Event.new("message" => str, "host" => @host)
      decorate(event)
      event["varnish_tag"] = tag
      event["varnish_fd"] = fd
      event["varnish_spec"] = spec
      event["varnish_bitmap"] = bitmap
      @q << event
    rescue => e
      @logger.warn("varnishlog exception: #{e.inspect}")
    ensure
      return 0
    end
  end
  
  public
  def teardown
    finished
  end # def teardown
end # class LogStash::Inputs::Stdin
