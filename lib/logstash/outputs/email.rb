# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# Send email when an output is received. Alternatively, you may include or
# exclude the email output execution using conditionals. 
class LogStash::Outputs::Email < LogStash::Outputs::Base

  config_name "email"
  milestone 1

  # This setting is deprecated in favor of Logstash's "conditionals" feature
  # If you were using this setting previously, please use conditionals instead.
  #
  # If you need help converting your older 'match' setting to a conditional,
  # I welcome you to join the #logstash irc channel on freenode or to email
  # the logstash-users@googlegroups.com mailling list and ask for help! :)
  config :match, :validate => :hash, :deprecated => true

  # The fully-qualified email address to send the email to.
  #
  # This field also accepts a comma-separated string of addresses, for example: 
  # "me@host.com, you@host.com"
  #
  # You can also use dynamic fields from the event with the %{fieldname} syntax.
  config :to, :validate => :string, :required => true

  # The fully-qualified email address for the From: field in the email.
  config :from, :validate => :string, :default => "logstash.alert@nowhere.com"

  # The fully qualified email address for the Reply-To: field.
  config :replyto, :validate => :string

  # The fully-qualified email address(es) to include as cc: address(es).
  #
  # This field also accepts a comma-separated string of addresses, for example: 
  # "me@host.com, you@host.com"
  config :cc, :validate => :string

  # How Logstash should send the email, either via SMTP or by invoking sendmail.
  config :via, :validate => :string, :default => "smtp"

  # Specify the options to use:
  #
  # Via SMTP: smtpIporHost, port, domain, userName, password, authenticationType, starttls
  #
  # Via sendmail: location, arguments
  #
  # If you do not specify any `options`, you will get the following equivalent code set in
  # every new mail object:
  #
  #     Mail.defaults do
  #       delivery_method :smtp, { :smtpIporHost         => "localhost",
  #                                :port                 => 25,
  #                                :domain               => 'localhost.localdomain',
  #                                :userName             => nil,
  #                                :password             => nil,
  #                                :authenticationType   => nil,(plain, login and cram_md5)
  #                                :starttls             => true  }
  #
  #       retriever_method :pop3, { :address             => "localhost",
  #                                 :port                => 995,
  #                                 :user_name           => nil,
  #                                 :password            => nil,
  #                                 :enable_ssl          => true }
  #
  #       Mail.delivery_method.new  #=> Mail::SMTP instance
  #       Mail.retriever_method.new #=> Mail::POP3 instance
  #     end
  #
  # Each mail object inherits the defaults set in Mail.delivery_method. However, on
  # a per email basis, you can override the method:
  #
  #     mail.delivery_method :sendmail
  #
  # Or you can override the method and pass in settings:
  #
  #     mail.delivery_method :sendmail, { :address => 'some.host' }
  #
  # You can also just modify the settings:
  #
  #     mail.delivery_settings = { :address => 'some.host' }
  #
  # The hash you supply is just merged against the defaults with "merge!" and the result
  # assigned to the mail object.  For instance, the above example will change only the
  # `:address` value of the global `smtp_settings` to be 'some.host', retaining all other values.
  config :options, :validate => :hash, :default => {}

  # Subject: for the email.
  config :subject, :validate => :string, :default => ""

  # Body for the email - plain text only.
  config :body, :validate => :string, :default => ""

  # HTML Body for the email, which may contain HTML markup.
  config :htmlbody, :validate => :string, :default => ""

  # Attachments - specify the name(s) and location(s) of the files.
  config :attachments, :validate => :array, :default => []

  # contenttype : for multipart messages, set the content-type and/or charset of the HTML part.
  # NOTE: this may not be functional (KH)
  config :contenttype, :validate => :string, :default => "text/html; charset=UTF-8"

  public
  def register
    require "mail"

    # Mail uses instance_eval which changes the scope of self so @options is
    # inaccessible from inside 'Mail.defaults'. So set a local variable instead.
    options = @options

    if @via == "smtp"
      Mail.defaults do
        delivery_method :smtp, {
          :address              => options.fetch("smtpIporHost", "localhost"),
          :port                 => options.fetch("port", 25),
          :domain               => options.fetch("domain", "localhost"),
          :user_name            => options.fetch("userName", nil),
          :password             => options.fetch("password", nil),
          :authentication       => options.fetch("authenticationType", nil),
          :enable_starttls_auto => options.fetch("starttls", false),
          :debug                => options.fetch("debug", false)
        }
      end
    elsif @via == 'sendmail'
      Mail.defaults do
        delivery_method :sendmail
      end
    else
      Mail.defaults do
        delivery_method :@via, options
      end
    end # @via tests
    @logger.debug("Email Output Registered!", :config => @config)
  end # def register

  public
  def receive(event)
    return unless output?(event)
      @logger.debug("Event being tested for Email", :tags => @tags, :event => event)
      # Set Intersection - returns a new array with the items that are the same between the two
      if !@tags.empty? && (event["tags"] & @tags).size == 0
         # Skip events that have no tags in common with what we were configured
         @logger.debug("No Tags match for Email Output!")
         return
      end

    @logger.debug? && @logger.debug("Match data for Email - ", :match => @match)
    successful = false
    matchName = ""
    operator = ""

    # TODO(sissel): Delete this once match support is removed.
    @match && @match.each do |name, query|
      if successful
        break
      else
        matchName = name
      end
      # now loop over the csv query
      queryArray = query.split(',')
      index = 1
      while index < queryArray.length
        field = queryArray.at(index -1)
        value = queryArray.at(index)
        index = index + 2
        if field == ""
          if value.downcase == "and"
            operator = "and"
          elsif value.downcase == "or"
            operator = "or"
          else
            operator = "or"
            @logger.error("Operator Provided Is Not Found, Currently We Only Support AND/OR Values! - defaulting to OR")
          end
        else
          hasField = event[field]
          @logger.debug? and @logger.debug("Does Event Contain Field - ", :hasField => hasField)
          isValid = false
          # if we have maching field and value is wildcard - we have a success
          if hasField
            if value == "*"
              isValid = true
            else
              # we get an array so we need to loop over the values and find if we have a match
              eventFieldValues = event[field]
              @logger.debug? and @logger.debug("Event Field Values - ", :eventFieldValues => eventFieldValues)
              eventFieldValues = [eventFieldValues] if not eventFieldValues.respond_to?(:each)
              eventFieldValues.each do |eventFieldValue|
                isValid = validateValue(eventFieldValue, value)
                if isValid # no need to iterate any further
                  @logger.debug("VALID CONDITION FOUND - ", :eventFieldValue => eventFieldValue, :value => value) 
                  break
                end
              end # end eventFieldValues.each do
            end # end value == "*"
          end # end hasField
          # if we have an AND operator and we have a successful == false break
          if operator == "and" && !isValid
            successful = false
          elsif operator == "or" && (isValid || successful)
            successful = true
          else
            successful = isValid
          end
        end
      end
    end # @match.each do

    # The 'match' setting is deprecated and optional. If not set,
    # default to success.
    successful = true if @match.nil?

    @logger.debug? && @logger.debug("Email Did we match any alerts for event : ", :successful => successful)

    if successful
      # first add our custom field - matchName - so we can use it in the sprintf function
      event["matchName"] = matchName unless matchName.empty?
      @logger.debug? and @logger.debug("Creating mail with these settings : ", :via => @via, :options => @options, :from => @from, :to => @to, :cc => @cc, :subject => @subject, :body => @body, :content_type => @contenttype, :htmlbody => @htmlbody, :attachments => @attachments, :to => to, :to => to)
      formatedSubject = event.sprintf(@subject)
      formattedBody = event.sprintf(@body)
      formattedHtmlBody = event.sprintf(@htmlbody)
      # we have a match(s) - send email
      mail = Mail.new
      mail.from = event.sprintf(@from)
      mail.to = event.sprintf(@to)
      if @replyto
        mail.reply_to = event.sprintf(@replyto)
      end
      mail.cc = event.sprintf(@cc)
      mail.subject = formatedSubject
      if @htmlbody.empty?
        formattedBody.gsub!(/\\n/, "\n") # Take new line in the email
        mail.body = formattedBody
      else
        mail.text_part = Mail::Part.new do
          content_type "text/plain; charset=UTF-8"
          formattedBody.gsub!(/\\n/, "\n") # Take new line in the email
          body formattedBody
        end
        mail.html_part = Mail::Part.new do
          content_type "text/html; charset=UTF-8"
          body formattedHtmlBody
        end
      end
      @attachments.each do |fileLocation|
        mail.add_file(fileLocation)
      end # end @attachments.each
      @logger.debug? and @logger.debug("Sending mail with these values : ", :from => mail.from, :to => mail.to, :cc => mail.cc, :subject => mail.subject)
      mail.deliver!
    end # end if successful
  end # def receive


  private
  def validateValue(eventFieldValue, value)
    valid = false
    # order of this if-else is important - please don't change it
    if value.start_with?(">=")# greater than or equal
      value.gsub!(">=","")
      if eventFieldValue.to_i >= value.to_i
        valid = true
      end
    elsif value.start_with?("<=")# less than or equal
      value.gsub!("<=","")
      if eventFieldValue.to_i <= value.to_i
        valid = true
      end
    elsif value.start_with?(">")# greater than
      value.gsub!(">","")
      if eventFieldValue.to_i > value.to_i
        valid = true
      end
    elsif value.start_with?("<")# less than
      value.gsub!("<","")
      if eventFieldValue.to_i < value.to_i
        valid = true
      end
    elsif value.start_with?("*")# contains
      value.gsub!("*","")
      if eventFieldValue.include?(value)
        valid = true
      end
    elsif value.start_with?("!*")# does not contain
      value.gsub!("!*","")
      if !eventFieldValue.include?(value)
        valid = true
      end
    elsif value.start_with?("!")# not equal
      value.gsub!("!","")
      if eventFieldValue != value
        valid = true
      end
    else # default equal
      if eventFieldValue == value
        valid = true
      end
    end
    return valid
  end # end validateValue()

end # class LogStash::Outputs::Email
