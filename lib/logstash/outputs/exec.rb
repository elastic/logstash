# encoding: utf-8
require "logstash/namespace"
require "logstash/outputs/base"

# This output will run a command for any matching event.
#
# Example:
# 
#     output {
#       exec {
#         type => abuse
#         command => "iptables -A INPUT -s %{clientip} -j DROP"
#       }
#     }
#
# Run subprocesses via system ruby function
#
# WARNING: if you want it non-blocking you should use & or dtach or other such
# techniques
class LogStash::Outputs::Exec < LogStash::Outputs::Base

  config_name "exec"
  milestone 1

  # Command line to execute via subprocess. Use dtach or screen to make it non blocking
  config :command, :validate => :string, :required => true

  public
  def register
    @logger.debug("exec output registered", :config => @config)
  end # def register

  public
  def receive(event)
    return unless output?(event)
    @logger.debug("running exec command", :command => event.sprintf(@command))
    system(event.sprintf(@command))
  end # def receive

end
