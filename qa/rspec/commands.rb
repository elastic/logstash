# encoding: utf-8
require_relative "./commands/debian"
require_relative "./commands/redhat"

module ServiceTester

  class Artifact

    attr_reader :client, :host

    def initialize(host, options={})
      @host     = host
      @options  = options
      @client = CommandsFactory.fetch(options["type"])
    end

    def name
      "logstash"
    end

    def hosts
      [@host]
    end

    def start_service
      client.start_service(name, host)
    end

    def stop_service
      client.stop_service(name, host)
    end

    def install(version)
      package = client.package_for(version)
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

    def self.fetch(type)
      case type
      when "debian"
        return DebianCommands.new
      when "redhat"
        return RedhatCommands.new
      else
        return
      end
    end
  end
end
