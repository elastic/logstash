require "logstash/outputs/base"
require "logstash/namespace"

#This output is used to send snmp v2c trap messages to a receiver specified in the host field.  An example use case would be 
#sending a trap to notify a monitoring system that a certain log message or metric has been seen.  From there the monitoring
#system could alert or take other action.

class LogStash::Outputs::Snmptrap < LogStash::Outputs::Base
        
 config_name "snmptrap"
 milestone 1

 default :codec, "line"

 #address of the host to send the trap/notification to
 config :host, :validate => :string, :required => true

 #the port to send the trap on
 config :port, :validate => :number, :default => 162

 #the community string to include
 config :community, :validate => :string, :default => "public"

 #the OID that specifies the event generating the trap message
 config :oid, :validate => :string, :required => true

 # directory of YAML MIB maps  (same format ruby-snmp uses)
 config :yamlmibdir, :validate => :string

 public
 def register
  require "snmp"
  #from snmp trap input plugin, thanks
  if @yamlmibdir
   @logger.info("checking #{@yamlmibdir} for MIBs")
   Dir["#{@yamlmibdir}/*.yaml"].each do |yamlfile|
    mib_name = File.basename(yamlfile, ".*")
    @yaml_mibs ||= []
    @yaml_mibs << mib_name
   end
   @logger.info("found MIBs: #{@yaml_mibs.join(',')}") if @yaml_mibs
  end
  @codec.on_event do |event|

   #set some variables for the trap sender
   trapsender_opts = {:trap_port => @port, :host => @host, :community => @community }

   #check for and add user specified mibs
   if !@yaml_mibs.empty?
    trapsender_opts.merge!({:mib_dir => @yamlmibdir, :mib_modules => @yaml_mibs})
   end
   #prep and do the full send
   SNMP::Manager.open(trapsender_opts) do |snmp|
    #set it up and send the whole event using the user specified codec
    varbind = SNMP::VarBind.new(@oid, SNMP::OctetString.new(event))
    #set uptime to 12345 since its not really used and reuse the oid that was input.
    snmp.trap_v2(12345, @oid, varbind)
   end
  end
 end 

 public
 def receive(event)
  return unless output?(event)
  if event == LogStash::SHUTDOWN
   finished
   return
  end
  @codec.encode(event)
 end
end
