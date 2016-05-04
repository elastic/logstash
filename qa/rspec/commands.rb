# encoding: utf-8
require_relative "./commands/debian"
require_relative "./commands/ubuntu"
require_relative "./commands/redhat"
require_relative "./commands/suse"
require "forwardable"

module ServiceTester

  class Artifact

    extend Forwardable
    def_delegators :@client, :installed?, :removed?, :running?

    attr_reader :host, :client

    def initialize(host, options={})
      @host    = host
      @options = options
      @client  = CommandsFactory.fetch(options["type"], options["host"])
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

    def install(version, base=ServiceTester::Base::LOCATION)
      package = client.package_for(version, base)
      client.install(package, host)
    end

    def uninstall
      client.uninstall(name, host)
    end

    def to_s
      "Artifact #{name}@#{host}"
    end
  end

  class CommandsFactory

    def self.fetch(type, host)
      case type
      when "debian"
        if host.start_with?("ubuntu")
          return UbuntuCommands.new
        else
          return DebianCommands.new
        end
      when "suse"
        return SuseCommands.new
      when "redhat"
        return RedhatCommands.new
      else
        return
      end
    end
  end
end
