# encoding: utf-8
require_relative "./commands/debian"
require_relative "./commands/ubuntu"
require_relative "./commands/redhat"
require_relative "./commands/suse"
require_relative "./commands/centos/centos-6"
require_relative "./commands/oel/oel-6"
require_relative "./commands/ubuntu/ubuntu-1604"
require_relative "./commands/suse/sles-11"

require "forwardable"

module ServiceTester

  # An artifact is the component being tested, it's able to interact with
  # a destination machine by holding a client and is basically provides all 
  # necessary abstractions to make the test simple.
  class Artifact

    extend Forwardable
    def_delegators :@client, :installed?, :removed?, :running?

    attr_reader :host, :client

    def initialize(host, options={})
      @host    = host
      @options = options
      @client  = CommandsFactory.fetch(options["type"], options["host"])
    end

    def hostname
      @options["host"]
    end

    def name
      "logstash"
    end

    def hosts
      [@host]
    end

    def snapshot
      client.snapshot(@options["host"])
    end

    def restore
      client.restore(@options["host"])
    end

    def start_service
      client.start_service(name, host)
    end

    def stop_service
      client.stop_service(name, host)
    end

    def install(options={})
      base      = options.fetch(:base, ServiceTester::Base::LOCATION)
      package   = client.package_for(filename(options), base)
      client.install(package, host)
    end

    def uninstall
      client.uninstall(name, host)
    end

    def run_command_in_path(cmd)
      client.run_command_in_path(cmd, host)
    end

    def run_command(cmd)
      client.run_command(cmd, host)
    end

    def plugin_installed?(name, version = nil)
      client.plugin_installed?(host, name, version)
    end

    def download(from, to)
      client.download(from, to , host)
    end
    
    def replace_in_gemfile(pattern, replace)
      client.replace_in_gemfile(pattern, replace, host)
    end

    def delete_file(path)
      client.delete_file(path, host)
    end

    def to_s
      "Artifact #{name}@#{host}"
    end

    private

    def filename(options={})
      snapshot  = options.fetch(:snapshot, true)
      "logstash-#{options[:version]}#{(snapshot ?  "-SNAPSHOT" : "")}"
    end
  end

  # Factory of commands used to select the right clients for a given type of OS and host name,
  # this give you as much granularity as required.
  class CommandsFactory

    def self.fetch(type, host)
      case type
      when "debian"
        if host.start_with?("ubuntu")
          if host == "ubuntu-1604"
            return Ubuntu1604Commands.new
          else
            return UbuntuCommands.new
          end
        else
          return DebianCommands.new
        end
      when "suse"
        if host == "sles-11"
          return Sles11Commands.new
        else
          return SuseCommands.new
        end
      when "redhat"
        if host == "centos-6"
          return Centos6Commands.new
        elsif host == "oel-6"
          return Oel6Commands.new
        else
          return RedhatCommands.new
        end
      else
        return
      end
    end
  end
end
