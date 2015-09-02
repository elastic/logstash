# encoding: utf-8
require "gems"

module LogStash
  module PluginManager
    class VersionValidators

      def self.validates(criteria={})
        check_for_major_version if criteria[:notice] == :major
      end

      # validate if there is any major version update so then we can ask the user if he is
      # sure to update or not.
      # @param plugin [String] A plugin name
      # @return [Boolean] true if updating to a major version is ok, false otherwise
      def self.check_for_major_version
        lambda do |plugin|
          latest_version  = ::Gems.versions(plugin.name)[0]['number'].split(".")
          current_version = ::Gem::Specification.find_by_name(plugin.name).version.version.split(".")
          if (latest_version[0].to_i > current_version[0].to_i)
            ## warn if users want to continue
            puts("You are updating #{plugin.name} to a new version #{latest_version.join('.')}, which may not be compatible with #{current_version.join('.')}. are you sure you want to proceed (Y/N)?")
            return ( "y" == STDIN.gets.strip.downcase ? true : false)
          end
          true
        end
      end
    end

  end
end
