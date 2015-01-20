require 'bundler'

module Bundler
  class RubygemsIntegration
    # When you call Bundler#setup it will bootstrap
    # a new rubygems environment and wipe all the existing
    # specs available if they are not defined in the current gemfile.
    # This patch change the behavior and will merge the specs.
    #
    # If you use :path to declare a gem in your gemfile this will create
    # a virtual specs for this gems and add will add them to the $LOAD_PATH
    #
    # Future >= rubygems 2.0
    class Future < RubygemsIntegration
      def stub_rubygems(specs)
        merged = merge_specs(specs)

        Gem::Specification.all = merged

        Gem.post_reset {
          Gem::Specification.all = merged
        }
      end

      def merge_specs(specs)
        gem_path_specifications = Gem::Specification.to_a
        
        # If the specs is available in the gem_path and declared in the gemfile
        # the gem in the Gemfile should have the priority.
        gem_path_specifications.delete_if { |specification| specs.to_a.collect(&:name).include?(specification.name) }

        merged_array = gem_path_specifications + specs.to_a
        SpecSet.new(merged_array)
      end
    end
  end  

  # Patch bundler to write a .lock file specific to the version of ruby.
  # This keeps MRI/JRuby/RBX from conflicting over the Gemfile.lock updates
  module SharedHelpers
    def default_lockfile
      ruby = "#{LogStash::Environment.ruby_engine}-#{LogStash::Environment.ruby_abi_version}"
      Pathname.new("#{default_gemfile}.#{ruby}.lock")
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
