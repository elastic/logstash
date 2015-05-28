# Bundler monkey patches
module ::Bundler
  # Patch bundler to write a .lock file specific to the version of ruby.
  # This keeps MRI/JRuby/RBX from conflicting over the Gemfile.lock updates
  module SharedHelpers
    def default_lockfile
      ruby = "#{LogStash::Environment.ruby_engine}-#{LogStash::Environment.ruby_abi_version}"
      Pathname.new("#{default_gemfile}.#{ruby}.lock")
    end
  end

  # Patch to prevent Bundler to save a .bundle/config file in the root 
  # of the application
  class Settings
    def set_key(key, value, hash, file)
      key = key_for(key)

      unless hash[key] == value
        hash[key] = value
        hash.delete(key) if value.nil?
      end

      value
    end
  end

  # Add the Bundler.reset! method which has been added in master but is not in 1.7.9.
  class << self
    unless self.method_defined?("reset!")
      def reset!
        @definition = nil
      end
    end
  end
end
