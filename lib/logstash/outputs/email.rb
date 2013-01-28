require "logstash/outputs/base"
require "logstash/namespace"


class LogStash::Outputs::Email < LogStash::Outputs::Base

  config_name "email"
  plugin_status "experimental"

  # The registered fields that we want to monitor
  # A hash of matches of field => value
  # Takes the form of:
  #
  #    { "match name", "field.in.event,value.expected, , operand(and/or),field.in.event,value.expected, , or...",
  #    "match name", "..." }
  #
  # The match name can be referenced using the `%{matchName}` field.
  config :match, :validate => :hash, :required => true

  # The To address setting - fully qualified email address to send to
  # This field also accept a comma separated list of emails like "me@host.com, you@host.com"
  # You can also use dynamic field from the event with the %{fieldname} syntax
  config :to, :validate => :string, :required => true

  # The From setting for email - fully qualified email address for the From:
  config :from, :validate => :string, :default => "logstash.alert@nowhere.com"

  # cc - send to others
  # See *to* field for accepted value description
  config :cc, :validate => :string, :default => ""

  # how to send email: either smtp or sendmail - default to 'smtp'
  config :via, :validate => :string, :default => "smtp"

  # the options to use:
  # smtp: address, port, enable_starttls_auto, user_name, password, authentication(bool), domain
  # sendmail: location, arguments
  # If you do not specify anything, you will get the following equivalent code set in
  # every new mail object:
  #
  #   Mail.defaults do
  #     delivery_method :smtp, { :address              => "localhost",
  #                              :port                 => 25,
  #                              :domain               => 'localhost.localdomain',
  #                              :user_name            => nil,
  #                              :password             => nil,
  #                              :authentication       => nil,(plain, login and cram_md5)
  #                              :enable_starttls_auto => true  }
  #
  #     retriever_method :pop3, { :address             => "localhost",
  #                               :port                => 995,
  #                               :user_name           => nil,
  #                               :password            => nil,
  #                               :enable_ssl          => true }
  #   end
  #
  #   Mail.delivery_method.new  #=> Mail::SMTP instance
  #   Mail.retriever_method.new #=> Mail::POP3 instance
  #
  # Each mail object inherits the default set in Mail.delivery_method, however, on
  # a per email basis, you can override the method:
  #
  #   mail.delivery_method :sendmail
  #
  # Or you can override the method and pass in settings:
  #
  #   mail.delivery_method :sendmail, { :address => 'some.host' }
  #
  # You can also just modify the settings:
  #
  #   mail.delivery_settings = { :address => 'some.host' }
  #
  # The passed in hash is just merged against the defaults with +merge!+ and the result
  # assigned the mail object.  So the above example will change only the :address value
  # of the global smtp_settings to be 'some.host', keeping all other values
  config :options, :validate => :hash, :default => {}

  # subject for email
  config :subject, :validate => :string, :default => ""

  # body for email - just plain text
  config :body, :validate => :string, :default => ""

  # body for email - can contain html markup
  config :htmlbody, :validate => :string, :default => ""

  # attachments - has of name of file and file location
  config :attachments, :validate => :array, :default => []

  # contenttype : for multipart messages, set the content type and/or charset of the html part
  config :contenttype, :validate => :string, :default => "text/html; charset=UTF-8"

  public
  def register
    require "mail"
    if @via == "smtp"
      debug = @options.include?("debug")
      if !debug
        debug = false
      else
        debug = @options.fetch("debug")
      end
      smtpIporHost = @options.include?("smtpIporHost")
      if !smtpIporHost
        smtpIporHost = "localhost"
      else
        smtpIporHost = @options.fetch("smtpIporHost")
      end
      domain = @options.include?("domain")
      if !domain
        domain = "localhost"
      else
        domain = @options.fetch("domain")
      end
      port = @options.include?("port")
      if !port
        port = 25
      else
        port = @options.fetch("port")
      end
      tls = @options.include?("starttls")
      if !tls
        tls = false
      else
        tls = @options.fetch("starttls")
      end
      pass = @options.include?("password")
      if !pass
        pass = ""
      else
        pass = @options.fetch("password")
      end
      userName = @options.include?("userName")
      if !userName
        userName = ""
      else
        userName = @options.fetch("userName")
      end
      authenticationType = @options.include?("authenticationType")
      if !authenticationType
        authenticationType = "plain"
      else
        authenticationType = @options.fetch("authenticationType")
      end
      Mail.defaults do
        delivery_method :smtp , { :address   => smtpIporHost,
                                  :port      => port,
                                  :domain    => domain,
                                  :user_name => userName,
                                  :password  => pass,
                                  :authentication => authenticationType,
                                  :enable_starttls_auto => tls,
                                  :debug => debug }
      end
    elsif @via == 'sendmail'
      Mail.defaults do
        delivery_method :sendmail
      end
    else
      Mail.defaults do
        delivery_method :@via, @options
      end
    end # @via tests
    @logger.debug("Email Output Registered!", :config => @config)
  end # def register

  public
  def receive(event)
    return unless output?(event)
      @logger.debug("Event being tested for Email", :tags => @tags, :event => event)
      # Set Intersection - returns a new array with the items that are the same between the two
      if !@tags.empty? && (event.tags & @tags).size == 0
         # Skip events that have no tags in common with what we were configured
         @logger.debug("No Tags match for Email Output!")
         return
      end

    @logger.debug("Match data for Email - ", :match => @match)
    successful = false
    matchName = ""
    operator = ""
    @match.each do |name, query|
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
          hasField = event.fields.has_key?(field)
          @logger.debug("Does Event Contain Field - ", :hasField => hasField)
          isValid = false
          # if we have maching field and value is wildcard - we have a success
          if hasField
            if value == "*"
              isValid = true
            else
              # we get an array so we need to loop over the values and find if we have a match
              eventFieldValues = event.fields.fetch(field)
              @logger.debug("Event Field Values - ", :eventFieldValues => eventFieldValues)
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

    @logger.debug("Email Did we match any alerts for event : ", :successful => successful)

    if successful
      # first add our custom field - matchName - so we can use it in the sprintf function
      event["matchName"] = matchName
      @logger.debug? and @logger.debug("Creating mail with these settings : ", :via => @via, :options => @options, :from => @from, :to => @to, :cc => @cc, :subject => @subject, :body => @body, :content_type => @contenttype, :htmlbody => @htmlbody, :attachments => @attachments, :to => to, :to => to)
      formatedSubject = event.sprintf(@subject)
      formattedBody = event.sprintf(@body)
      formattedHtmlBody = event.sprintf(@htmlbody)
      # we have a match(s) - send email
      mail = Mail.new
      mail.from = event.sprintf(@from)
      mail.to = event.sprintf(@to)
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
