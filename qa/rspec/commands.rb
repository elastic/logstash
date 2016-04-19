# encoding: utf-8
require_relative "./debian/commands"
require_relative "./centos/commands"

module ServiceTester
  class CommandsFactory

    def self.fetch(type)
      case type
      when :debian
        return DebianCommands.new
      when :centos
        return CentosCommands.new
      else
        return
      end
    end
  end
end
