require "logstash/namespace"
require "logstash/outputs/base"
 
# The zabbix output is used for sending item data to zabbix via the
# zabbix_sender executable.
#
# For this output to work, your event must have the following fields:
#
# * "zabbix_host"    (the host configured in Zabbix)
# * "zabbix_item"    (the item key on the host in Zabbix)
#
# In Zabbix, create your host with the same name (no spaces in the name of 
# the host supported) and create your item with the specified key as a
# Zabbix Trapper item.
#
# The easiest way to use this output is with the grep filter.
# Presumably, you only want certain events matching a given pattern
# to send events to zabbix, so use grep to match and also to add the required
# fields.
#
#      filter {
#        grep {
#          type => "linux-syslog"
#          match => [ "@message", "(error|ERROR|CRITICAL)" ]
#          add_tag => [ "zabbix-sender" ]
#          add_field => [
#            "zabbix_host", "%{@source_host}",
#            "zabbix_item", "item.key"
#          ]
#       }
#     }
#      
#     output {
#       zabbix {
#         # only process events with this tag
#         tags => "zabbix-sender"
#  
#         # specify the hostname or ip of your zabbix server
#         # (defaults to localhost)
#         host => "localhost"
#  
#         # specify the port to connect to (default 10051)
#         port => "10051"
#  
#         # specify the path to zabbix_sender
#         # (defaults to "/usr/local/bin/zabbix_sender")
#         zabbix_sender => "/usr/local/bin/zabbix_sender"
#       }
#     }
class LogStash::Outputs::Zabbix < LogStash::Outputs::Base
 
  config_name "zabbix"
  plugin_status "beta"

  config :host, :validate => :string, :default => "localhost"
  config :port, :validate => :number, :default => 10051
  config :zabbix_sender, :validate => :path, :default => "/usr/local/bin/zabbix_sender"
 
  public
  def register
    # nothing to do
  end # def register
 
  public
  def receive(event)
    return unless output?(event)
 
    if !File.exists?(@zabbix_sender)
      @logger.warn("Skipping zabbix output; zabbix_sender file is missing",
                   :zabbix_sender => @zabbix_sender, :missed_event => event)
      return
    end
 
    host = event.fields["zabbix_host"]
    if !host
      @logger.warn("Skipping zabbix output; zabbix_host field is missing",
                   :missed_event => event)
      return
    end
    host = host.first if host.is_a?(Array)
 
    item = event.fields["zabbix_item"]
    if !item
      @logger.warn("Skipping zabbix output; zabbix_item field is missing",
                   :missed_event => event)
      return
    end
    item = item.first if item.is_a?(Array)
 
    zmsg = event.message
    zmsg = zmsg.gsub("\n", "\\n")
    zmsg = zmsg.gsub(/"/, "\\\"")
 
    cmd = "#{@zabbix_sender} -z #{@host} -p #{@port} -s #{host} -k #{item} -o \"#{zmsg}\" 2>/dev/null >/dev/null"
 
    @logger.debug("Running zabbix command", :command => cmd)
    begin
      # TODO(sissel): Update this to use IO.popen so we can capture the output and
      # log it accordingly.
      system(cmd)
    rescue => e
      @logger.warn("Skipping zabbix output; error calling zabbix_sender",
                   :command => cmd, :missed_event => event,
                   :exception => e, :backtrace => e.backtrace)
    end
  end # def receive
end # class LogStash::Outputs::Zabbix
