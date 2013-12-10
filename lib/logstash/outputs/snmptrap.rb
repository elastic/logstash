require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Snmptrap < LogStash::Outputs::Base
        
        #USAGE:
        #output {
        #  snmpwalk {
        #    codec => ... # codec (optional), default: "line"
        #    host => ... # string (optional), default: "0.0.0.0"
        #    port => ... # number (optional), default: "162"
        #    community => ... # string (optional), default: "public"
        #    oid => ... # string (required)
        #    yamilmibdir => ... # string (optional)
        #  }
        #}

	config_name "snmptrap"
	milestone 1

        default :codec, "line"

	#address of the host to send the trap/notification to
	config :host, :validate => :string, :default => "0.0.0.0"

	#the port to send the trap on
	config :port, :validate => :number, :default => 162

	#the community string to include
	config :community, :validate => :string, :default => "public"

	#the OID that specifies the event generating the trap message
	config :oid, :validate => :string, :required => true

	# directory of YAML MIB maps  (same format ruby-snmp uses)
	config :yamlmibdir, :validate => :string


	def initialize(*args)
		super(*args)
	end

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
				#we dont actually care about the sys_up_time...do we.  Also I am re-using the oid that was input.
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
