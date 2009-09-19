# Adapted from Autotest::Rails, RSpec's autotest class, as well as merb-core's.
require 'autotest'

class RspecCommandError < StandardError; end

# This class maps your application's structure so Autotest can understand what 
# specs to run when files change.
#
# Fixtures are _not_ covered by this class. If you change a fixture file, you 
# will have to run your spec suite manually, or, better yet, provide your own 
# Autotest map explaining how your fixtures are set up.
class Autotest::MerbRspec < Autotest
  def initialize
    super

    # Ignore any happenings in these directories
    add_exception %r%^\./(?:doc|log|public|tmp|\.git|\.hg|\.svn|framework|gems|schema|\.DS_Store|autotest|bin|.*\.sqlite3|.*\.thor)% 
    # Ignore SCM directories and custom Autotest mappings
    %w[.svn .hg .git .autotest].each { |exception| add_exception(exception) }

    # Ignore any mappings that Autotest may have already set up
    clear_mappings

    # Anything in /lib could have a spec anywhere, if at all. So, look for
    # files with roughly the same name as the file in /lib
    add_mapping %r%^lib\/(.*)\.rb% do |_, m|
      files_matching %r%^spec\/#{m[1]}%
    end

    add_mapping %r%^spec/(spec_helper|shared/.*)\.rb$% do
      all_specs
    end

    # Changing a spec will cause it to run itself
    add_mapping %r%^spec/.*\.rb$% do |filename, _|
      filename
    end

    # Any change to a model will cause it's corresponding test to be run
    add_mapping %r%^app/models/(.*)\.rb$% do |_, m|
      spec_for(m[1], 'model')
    end

    # Any change to global_helpers will result in all view and controller
    # tests being run
    add_mapping %r%^app/helpers/global_helpers\.rb% do
      files_matching %r%^spec/(views|controllers|helpers|requests)/.*_spec\.rb$%
    end

    # Any change to a helper will cause its spec to be run
    add_mapping %r%^app/helpers/((.*)_helper(s)?)\.rb% do |_, m|
      spec_for(m[1], 'helper')
    end

    # Changes to a view cause its spec to be run
    add_mapping %r%^app/views/(.*)/% do |_, m|
      spec_for(m[1], 'view')
    end

    # Changes to a controller result in its corresponding spec being run. If
    # the controller is the exception or application controller, all
    # controller specs are run.
    add_mapping %r%^app/controllers/(.*)\.rb$% do |_, m|
      if ["application", "exception"].include?(m[1])
        files_matching %r%^spec/controllers/.*_spec\.rb$%
      else
        spec_for(m[1], 'controller')
      end
    end

    # If a change is made to the router, run controller, view and helper specs
    add_mapping %r%^config/router.rb$% do
      files_matching %r%^spec/(controllers|views|helpers)/.*_spec\.rb$%
    end

    # If any of the major files governing the environment are altered, run
    # everything
    add_mapping %r%^config/(init|rack|environments/test).*\.rb|database\.yml% do 
      all_specs
    end
  end

  def failed_results(results)
    results.scan(/^\d+\)\n(?:\e\[\d*m)?(?:.*?Error in )?'([^\n]*)'(?: FAILED)?(?:\e\[\d*m)?\n(.*?)\n\n/m)
  end

  def handle_results(results)
    @failures      = failed_results(results)
    @files_to_test = consolidate_failures(@failures)
    @files_to_test.empty? && !$TESTING ? hook(:green) : hook(:red)
    @tainted = !@files_to_test.empty?
  end

  def consolidate_failures(failed)
    filters = Hash.new { |h,k| h[k] = [] }
    failed.each do |spec, failed_trace|
      if f = test_files_for(failed).find { |f| f =~ /spec\// }
        filters[f] << spec
        break
      end
    end
    filters
  end

  def make_test_cmd(specs_to_runs)
    [
      ruby,
      "-S",
      spec_command,
      add_options_if_present,
      files_to_test.keys.flatten.join(' ')
    ].join(' ')
  end

  def add_options_if_present
    File.exist?("spec/spec.opts") ? "-O spec/spec.opts " : ""
  end

  # Finds the proper spec command to use. Precendence is set in the
  # lazily-evaluated method spec_commands.  Alias + Override that in
  # ~/.autotest to provide a different spec command then the default
  # paths provided.
  def spec_command(separator=File::ALT_SEPARATOR)
    unless defined?(@spec_command)
      @spec_command = spec_commands.find { |cmd| File.exists?(cmd) }

      raise RspecCommandError, "No spec command could be found" unless @spec_command

      @spec_command.gsub!(File::SEPARATOR, separator) if separator
    end
    @spec_command
  end

  # Autotest will look for spec commands in the following
  # locations, in this order:
  #
  #   * default spec bin/loader installed in Rubygems
  #   * any spec command found in PATH
  def spec_commands
    [File.join(Config::CONFIG['bindir'], 'spec'), 'spec']
  end

private

  # Runs +files_matching+ for all specs
  def all_specs
    files_matching %r%^spec/.*_spec\.rb$%
  end

  # Generates a path to some spec given its kind and the match from a mapping
  #
  # ==== Arguments
  # match<String>:: the match from a mapping
  # kind<String>:: the kind of spec that the match represents
  #
  # ==== Returns
  # String
  #
  # ==== Example
  #   > spec_for('post', :view')
  #   => "spec/views/post_spec.rb"
  def spec_for(match, kind)
    File.join("spec", kind + 's', "#{match}_spec.rb")
  end
end
