require "logstash/outputs/base"
require "logstash/namespace"
require "net/smtp"

# Mailer output. Sends a mail of each log line that comes with the configured tags
# Supports only simple SMTP without auth or SSL
# Default conf should work with local MTA setup
#
# Config example:
#
# filter {
#   grep {
#     type => "syslog" # for logs of type "syslog"
#     match => [ "@message" , "(not responding, still trying|Lost connection to the server )" ] # contain not responding, still trying OR Lost connection to the server
#     add_tag => [ "mailer" ]
#     drop => false
#     add_field => [ "subject", "Storage Timeout" ]
#   }
#   grep {
#     type => "syslog" # for logs of type "syslog"
#     match => [ "@message" , "(?=vendor)(?!execution expired)" ] # contain vendor AND NOT execution expired
#     add_tag => [ "mailer" ]
#     drop => false
#     add_field => [ "subject", "Application _Unknown Errors_" ]
#   }
#   grep {
#     type => "syslog" # for logs of type "syslog"
#     match => [ "@message" , "execution expired" ] # contain vendor AND execution expired
#     match => [ "@message" , "vendor" ]
#     add_tag => [ "mailer" ]
#     drop => false
#     add_field => [ "subject", "Application _Execution Expired_" ]
#   }
# }
# output {
#   mailer {
#     tags => "mailer"
#     from => "logstash@localhost"
#     to => [ "oper@localhost" ]
#   }
# #  elasticsearch {
# #    host => "localhost"
# #    cluster => "MyCluster"
# #  }
# }
class LogStash::Outputs::Mailer < LogStash::Outputs::Base

  config_name "mailer"

  config :subject, :validate => :string, :default => "Logstash notification"

  config :from, :validate => :string, :default => "root@localhost"

  config :to, :validate => :array, :default => [ "root@localhost" ]

  config :server, :validate => :string, :default => "localhost"

  config :port, :validate => :number, :default => 25

  config :tags, :validate => :array, :default => []

  public
  def register
    # nothing to do
  end # def register

  public
  def receive(event)
    if !@tags.empty?
      if (event.tags & @tags).size == 0
        return
      else
	@logger.debug("#{event.to_s} ! Sending mail...")
        @subject = event.fields["subject"] ||= @subject
        Net::SMTP.start(@server, @port) do |smtp|
          smtp.send_message "Subject: #{@subject}\n\n #{event.to_s}", @from, @to
        end
      end
    end
  end #def receive
end # class LogStash::Outputs::Mailer
