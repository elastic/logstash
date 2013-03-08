require "logstash/inputs/base"
require "logstash/namespace"

# Read snmp trap messages as events
#
# SNMP varbinds are coerced to 'name=value' string pairs, separated by newlines.
# This results in a @message that looks like:
#   "SNMPv2-MIB::sysUpTime.0=134 days, 10:12:47.90\nSNMPv2-MIB::snmpTrapOID.0=SNMPv2-SMI::enterprises.5951.1.1.0.9"
#
# You can transform this into useful @fields with a filter like:
#
# filter { kv { field_split => "\n"} }
#

class LogStash::Inputs::Snmptrap < LogStash::Inputs::Base
  config_name "snmptrap"
  plugin_status "experimental"

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Remember that ports less than 1024 (privileged
  # ports) may require root to use. hence the default of 1062.
  config :port, :validate => :number, :default => 1062

  # SNMP Community String to listen for.
  config :community, :validate => :string, :default => "public"


  def initialize(*args)
    super(*args)
  end # def initialize

  public
  def register
    require "snmp"
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
    @snmptrap.on_trap_default do |trap|
      begin
        varbind_pairs = []
        trap.each_varbind do |vb|
          varbind_pairs << "#{vb.name.to_s}=#{vb.value.to_s}"
        end
        event = to_event(varbind_pairs.join("\n"), trap.source_ip)
        @logger.debug("SNMP Trap received: ", :trap_object => trap.inspect)
        output_queue << event if event
      rescue => event
        @logger.error("Failed to create event", :trap_object => trap.inspect)
      end
    end
    @snmptrap.join
  end # def snmptrap_listener

end # class LogStash::Inputs::Snmptrap
