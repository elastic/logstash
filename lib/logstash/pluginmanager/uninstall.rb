require "logstash/namespace"
require "logstash/logging"
require "logstash/errors"
require "logstash/environment"
require "logstash/pluginmanager/util"
require "clamp"

require "logstash/gemfile"
require "bundler/cli"
require "logstash/bundler_patch"

class LogStash::PluginManager::Uninstall < Clamp::Command
  parameter "PLUGIN", "plugin name"


  def execute
    unless File.writable?(LogStash::Environment::GEMFILE_PATH)
      $stderr.puts("File #{LogStash::Environment::GEMFILE_PATH} does not exist or is not writable, aborting")
      return 99
    end

    gemfile = LogStash::Gemfile.new(File.new(LogStash::Environment::GEMFILE_PATH, "r+")).load
    # keep a copy of the gemset to revert on error
    original_gemset = gemfile.gemset.copy

    unless gemfile.find(plugin)
      $stderr.puts("This plugin has not been previously installed, aborting")
      return 99
    end

    # do we really need to verify this here?
    return 99 unless LogStash::PluginManager.is_logstash_plugin?(plugin)

    # since we previously did a gemfile.find(plugin) there is no reason why
    # remove would not work (return nil) here
    if gemfile.remove(plugin)
      gemfile.save

      puts("Uninstalling #{plugin}")

      # any errors will be logged to $stderr by invoke_bundler!
      output, exception = LogStash::PluginManager.invoke_bundler!(:clean => true)

      if ENV["DEBUG"]
        $stderr.puts(output)
        $stderr.puts("Error: #{exception.class}, #{exception.message}") if exception
      end

     if exception
        # revert to original Gemfile content
        gemfile.gemset = original_gemset
        gemfile.save
        return 99
      end
    end

    return 0
  end


  # def execute
  #   ::Gem.configuration.verbose = false

  #   puts ("Validating removal of #{plugin}.")

  #   #
  #   # TODO: This is a special case, Bundler doesnt allow you to uninstall 1 gem.
  #   # Bundler will only uninstall the gems if they dont exist in his Gemfile.lock
  #   # (source of truth)
  #   #
  #   unless gem_data = LogStash::PluginManager::Util.logstash_plugin?(plugin)
  #     $stderr.puts ("Trying to remove a non logstash plugin. Aborting")
  #     return 99
  #   end

  #   puts ("Uninstalling plugin '#{plugin}' with version '#{gem_data.version}'.")
  #   ::Gem::Uninstaller.new(plugin, {}).uninstall
  #   return
  # end

end # class Logstash::PluginManager
