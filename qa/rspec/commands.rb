# encoding: utf-8
require_relative "./debian/commands"
require_relative "./redhat/commands"

module ServiceTester
  class CommandsFactory

    def self.fetch(type)
      case type
      when "debian"
        return DebianCommands.new
      when "redhat"
        return CentosCommands.new
      else
        return
      end
    end
  end
end
