require "logstash/inputs/base"
require "logstash/namespace"
require "snmp"

# Read snmp trap messages as events
#
# Resulting @message looks like :
#   #<SNMP::SNMPv1_Trap:0x6f1a7a4 @varbind_list=[#<SNMP::VarBind:0x2d7bcd8f @value="teststring", 
#   @name=[1.11.12.13.14.15]>], @timestamp=#<SNMP::TimeTicks:0x1af47e9d @value=55>, @generic_trap=6, 
#   @enterprise=[1.2.3.4.5.6], @source_ip="127.0.0.1", @agent_addr=#<SNMP::IpAddress:0x29a4833e @value="\xC0\xC1\xC2\xC3">, 
#   @specific_trap=99>
#
# TODO : work out how to break it down into field.keys.   looks like varbind_list can have multiple entries which might 
#        mean multiple events per trap ?

class LogStash::Inputs::Snmptrap < LogStash::Inputs::Base
  config_name "snmptrap"
  plugin_status "experimental"

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use.
  config :port, :validate => :number, :default => 1062

  # SNMP Community String to listen for.
  config :community, :validate => :string, :default => "public"


  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    @snmptrap = nil
  end # def register

  public
  def run(output_queue)
    LogStash::Util::set_thread_name("input|snmptrap|#{@community}")
    begin
      # snmp trap server
      snmptrap_listener(output_queue)
    rescue => e
      @logger.warn("SNMP Trap listener died", :exception => e, :backtrace => e.backtrace)
      sleep(5)
      retry
    end # begin
  end # def run

  private
  def snmptrap_listener(output_queue)
    @logger.info("It's a Trap!", :host => @host, :port => @port, :community => @community)
    @snmptrap = SNMP::TrapListener.new(:Port => @port, :Community => @community, :Host => @host) 
    loop do
      @snmptrap.on_trap_default do |trap|
        begin
          event = to_event(trap.inspect, trap.source_ip)
          @logger.info("SNMP Trap received: ", :trap_object => trap.inspect)
          output_queue << event if event
        rescue => event
          @logger.error("Failed to create event", :trap_object => trap.inspect)
        end
      end
    end
  end # def snmptrap_listener

end # class LogStash::Inputs::Snmptrap
