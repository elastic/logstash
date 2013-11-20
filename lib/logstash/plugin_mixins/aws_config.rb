# encoding: utf-8
require "logstash/config/mixin"

module LogStash::PluginMixins::AwsConfig

  @logger = Cabin::Channel.get(LogStash)

  # This method is called when someone includes this module
  def self.included(base)
    # Add these methods to the 'base' given.
    base.extend(self)
    base.setup_aws_config
  end

  US_EAST_1 = "us-east-1"
  
  public
  def setup_aws_config
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
    # The AWS SDK for Ruby defaults to SSL so we preserve that
    config :use_ssl, :validate => :boolean, :default => true

    # URI to proxy server if required
    config :proxy_uri, :validate => :string

    # Path to YAML file containing a hash of AWS credentials.   
    # This file will only be loaded if `access_key_id` and
    # `secret_access_key` aren't set. The contents of the
    # file should look like this:
    #
    #     :access_key_id: "12345"
    #     :secret_access_key: "54321"
    #
    config :aws_credentials_file, :validate => :string
  end

  public
  def aws_options_hash
    if @access_key_id.is_a?(NilClass) ^ @secret_access_key.is_a?(NilClass)
      @logger.warn("Likely config error: Only one of access_key_id or secret_access_key was provided but not both.")
    end

    if ((!@access_key_id || !@secret_access_key)) && @aws_credentials_file
      access_creds = YAML.load_file(@aws_credentials_file)

      @access_key_id = access_creds[:access_key_id]
      @secret_access_key = access_creds[:secret_access_key]
    end

    opts = {}

    if (@access_key_id && @secret_access_key)
      opts[:access_key_id] = @access_key_id
      opts[:secret_access_key] = @secret_access_key
    end

    opts[:use_ssl] = @use_ssl

    if (@proxy_uri)
      opts[:proxy_uri] = @proxy_uri
    end

    # The AWS SDK for Ruby doesn't know how to make an endpoint hostname from a region
    # for example us-west-1 -> foosvc.us-west-1.amazonaws.com
    # So our plugins need to know how to generate their endpoints from a region
    # Furthermore, they need to know the symbol required to set that value in the AWS SDK
    # Classes using this module must implement aws_service_endpoint(region:string)
    # which must return a hash with one key, the aws sdk for ruby config symbol of the service
    # endpoint, which has a string value of the service endpoint hostname
    # for example, CloudWatch, { :cloud_watch_endpoint => "monitoring.#{region}.amazonaws.com" }
    # For a list, see https://github.com/aws/aws-sdk-ruby/blob/master/lib/aws/core/configuration.rb
    opts.merge!(self.aws_service_endpoint(@region))
    
    return opts
  end # def aws_options_hash

end
