require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

# Read mail from IMAP servers
#
# Periodically scans INBOX and moves any read messages
# to the trash.
class LogStash::Inputs::IMAP < LogStash::Inputs::Base
  config_name "imap"
  milestone 1
  ISO8601_STRFTIME = "%04d-%02d-%02dT%02d:%02d:%02d.%06d%+03d:00".freeze

  config :host, :validate => :string, :required => true
  config :port, :validate => :number

  config :user, :validate => :string, :required => true
  config :password, :validate => :password, :required => true
  config :secure, :validate => :boolean, :default => true

  config :fetch_count, :validate => :number, :default => 50
  config :lowercase_headers, :validate => :boolean, :default => true
  config :check_interval, :validate => :number, :default => 300

  public
  def register
    require "net/imap" # in stdlib
    require "mail" # gem 'mail'

    if @port.nil?
      if @secure
        @port = 993
      else
        @port = 143
      end
    end
  end # def register

  def connect
    imap = Net::IMAP.new(@host, :port => @port, :ssl => @secure)
    imap.login(@user, @password.value)
    return imap
  end

  def run(queue)
    Stud.interval(@check_interval) do
      check_mail(queue)
    end
  end

  def check_mail(queue)
    # TODO(sissel): handle exceptions happening during runtime:
    # EOFError, OpenSSL::SSL::SSLError
    imap = connect
    imap.select("INBOX")
    ids = imap.search("ALL")

    ids.each_slice(@fetch_count) do |id_set|
      items = imap.fetch(id_set, "RFC822")
      items.each do |item|
        mail = Mail.read_from_string(item.attr["RFC822"])
        queue << mail_to_event(mail)
      end
    end

    imap.close
    imap.disconnect
  end # def run

  def mail_to_event(mail)
    # TODO(sissel): What should a multipart message look like as an event?
    # For now, just take the plain-text part and set it as the message.
    if mail.parts.count == 0
      # No multipart message, just use the body as the event text
      message = mail.body.decoded
    else
      # Multipart message; use the first text/plain part we find
      message = mail.parts.find { |p| p.content_type =~ /^text\/plain/ }.decoded
    end

    event = to_event(message, "imap://#{@user}@#{@host}/#{m.from.first rescue ""}")
   
    # Use the 'Date' field as the timestamp
    t = mail.date.to_time.gmtime
    event["@timestamp"] = sprintf(ISO8601_STRFTIME, t.year, t.month,
                                  t.day, t.hour, t.min, t.sec, t.tv_usec,
                                  t.utc_offset / 3600)

    # Add fields: Add message.header_fields { |h| h.name=> h.value }
    mail.header_fields.each do |header|
      if @lowercase_headers
        # 'header.name' can sometimes be a Mail::Multibyte::Chars, get it in
        # String form
        name = header.name.to_s.downcase
      else
        name = header.name.to_s
      end
      # Call .to_s on the value just in case it's some weird Mail:: object
      # thing.
      value = header.value.to_s

      # Assume we already processed the 'date' above.
      next if name == "Date"

      case event[name]
        # promote string to array if a header appears multiple times
        # (like 'received')
        when String; event[name] = [event[name], value]
        when Array; event[name].is_a?(Array)
        when nil; event[name] = value
      end
    end # mail.header_fields.each

    return event
  end # def handle

  public
  def teardown
    $stdin.close
    finished
  end # def teardown
end # class LogStash::Inputs::IMAP
