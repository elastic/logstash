require 'net/ssh'

module IntegrationSpecHelper
  class Configuration
    attr_accessor :username, :password, :host, :port
    def initialize
      @username = "vagrant"
      @host     = "127.0.0.1"
      @password = ""
      @port     = 22
    end
  end
end

module IntegrationSpecHelper

  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  def command(cmd)
    host     = config.host
    username = config.username
    stdout, stderr, exit_status = "", "", -1
    Net::SSH.start(host, username, {:password => config.password, :port => config.port}) do |ssh|
      ssh.exec!(cmd) do |channel, stream, data|
        stdout << data if stream == :stdout
        stderr << data if stream == :stderr
        channel.on_request("exit-status") do |ch, _data|
          exit_status = _data.read_long
        end
      end
    end
    { :stdout => stdout, :stderr => stderr, :exit_status => exit_status }
  end

  private
  def config
    IntegrationSpecHelper.configuration
  end
end

RSpec.configure do |c|
  c.include IntegrationSpecHelper
end
