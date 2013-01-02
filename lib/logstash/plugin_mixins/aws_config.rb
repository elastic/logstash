require "logstash/config/mixin"

module LogStash::PluginMixins::AwsConfig
  include LogStash::Config::Mixin

  @logger = LogStash::Logger.new(STDOUT)
  @logger.level = $DEBUG ? :debug : :warn

  US_EAST_1 = "us-east-1"
  # The AWS Region
  config :region, :validate => [US_EAST_1, "us-west-1", "us-west-2",
                                "eu-west-1", "ap-southeast-1", "ap-southeast-2",
                                "ap-northeast-1", "sa-east-1", "us-gov-west-1"], :default => US_EAST_1

  # This plugin uses the AWS SDK and supports several ways to get credentials, which will be tried in this order...   
  # 1. Static configuration, using `access_key_id` and `secret_access_key` params in logstash plugin config   
  # 2. External credentials file specified by `aws_credentials_file`   
  # 3. Environment variables `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`   
  # 4. Environment variables `AMAZON_ACCESS_KEY_ID` and `AMAZON_SECRET_ACCESS_KEY`   
  # 5. IAM Instance Profile (available when running inside EC2)   
  config :access_key_id, :validate => :string

  # The AWS Secret Access Key
  config :secret_access_key, :validate => :string

  # Should we require (true) or disable (false) using SSL for communicating with the AWS API   
  # If this option is not provided, the AWS SDK for Ruby default will be used
  config :use_ssl, :validate => :boolean

  # Path to YAML file containing a hash of AWS credentials.   
  # This file will only be loaded if `access_key_id` and
  # `secret_access_key` aren't set. The contents of the
  # file should look like this:
  #
  #     ---
  #     :access_key_id: "12345"
  #     :secret_access_key: "54321"
  #
  config :aws_credentials_file, :validate => :string

  def aws_options_hash
    if @access_key_id ^ @secret_access_key
      @logger.warn("Only one of access_key_id or secret_access_key was provided but not both.")
    end

    if (!(@access_key_id && @secret_access_key)) && @aws_credentials_file
      access_creds = YAML.load_file(@aws_credentials_file)

      @access_key_id = access_creds[:access_key_id]
      @secret_access_key = access_creds[:secret_access_key]
    end
    
    opts = {}
    
    if (@access_key_id && @secret_access_key)
      opts[:access_key_id] = @access_key_id
      opts[:secret_access_key] = @secret_access_key
    end

    if @use_ssl
      opts[:use_ssl] = @use_ssl
    end

    opts[:region] = @region
    
    return opts
  end # def aws_options_hash

end