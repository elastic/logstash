# Patch bundler to write a .lock file specific to the version of ruby.
# This keeps MRI/JRuby/RBX from conflicting over the Gemfile.lock updates
module Bundler
  module SharedHelpers
    def default_lockfile
      ruby = "#{LogStash::Environment.ruby_engine}-#{LogStash::Environment.ruby_abi_version}"
      return Pathname.new("#{default_gemfile}.#{ruby}.lock")
    end
  end
end

