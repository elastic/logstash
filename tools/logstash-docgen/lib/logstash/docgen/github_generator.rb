# encoding: utf-8
require "logstash/docgen/parser"
require "logstash/docgen/task_runner"
require "logstash/docgen/util"
require "stud/trap"
require "git"
require "bundler"
require "open3"
require "octokit"
require "fileutils"

module LogStash module Docgen
  # Class to encapsulate any operations needed to actually run the doc
  # generation on a specific plugin.
  #
  # Since the doc generation need access to the current library/dependency and we
  # dont want to polute the main exection namespace with libraries that could be incompatible
  # each execution of the doc is is own process.
  #
  # Its a lot slower, but we know for sure that it uses the latest dependency for each plugins.
  class Plugin
    class CommandException < StandardError; end

    GITHUB_URI = "https://github.com/logstash-plugins/%s"

    BUNDLER_CMD = "bundler install --jobs 8 --quiet --path /tmp/vendor"
    RAKE_VENDOR_CMD = "bundle exec rake vendor"
    RAKE_DOC_ASCIIDOC = "bundle exec rake doc:asciidoc"

    # Content needed to inject to make the generator work
    GEMFILE_CHANGES = "gem 'logstash-docgen', :path => \"#{File.expand_path(File.join(File.dirname(__FILE__), "..", "..", ".."))}\""
    RAKEFILE_CHANGES = "require 'logstash/docgen/plugin_doc'"

    attr_reader :path, :full_name

    def initialize(full_name, temporary_path)
      @full_name = full_name
      @path = File.join(temporary_path, full_name)
    end

    def type
      full_name.split("-")[1]
    end

    def name
      full_name.split("-").last
    end

    def generate(destination)
      fetch
      inject_docgen
      bundle_install
      rake_vendor
      generate_doc(destination)
    end

    private
    def fetch
      repository = sprintf(GITHUB_URI, full_name)
      # by default lets just get the tip of the branch

      if Dir.exist?(path)
        g = Git.init(path)
        g.reset
        g.fetch
        g.merge("origin/master")
      else
        g = Git.clone(repository, path, :depth => 1 )
      end
    end

    def inject_docgen
      File.open(File.join(path, "Gemfile"), "a") do |f|
        f.write("\n#{GEMFILE_CHANGES}")
      end

      File.open(File.join(path, "Rakefile"), "a") do |f|
        f.write("\n#{RAKEFILE_CHANGES}")
      end
    end

    def rake_vendor
      run_in_directory(RAKE_VENDOR_CMD)
    end

    def generate_doc(destination)
      output = run_in_directory(RAKE_DOC_ASCIIDOC)
      destination = File.join(destination, "#{type}s")
      FileUtils.mkdir_p(destination)
      IO.write(File.join(destination, "#{name}.asciidoc"), output.read)
    end

    def bundle_install
      run_in_directory(BUNDLER_CMD)
    end

    def run_in_directory(cmd = nil, &block)
      Dir.chdir(path) do
        Bundler.with_clean_env do
          stdin, stdout, stderr, wait_thr = Open3.popen3(cmd)
          if wait_thr.value.success?
            return stdout
          else
            raise CommandException.new, "cmd: #{cmd}, stdout: #{stdout.read}, stderr: #{stderr.read}"
          end
        end
      end
    end
  end


  # This class orchestrate all the operation between the `logstash-plugins` organization and the
  # doc build for each plugin.
  class DocumentationGenerator
    LOGSTASH_PLUGINS_ORGANIZATION = "logstash-plugins"

    attr_reader :plugins, :temporary_path, :config

    def initialize(plugins, target, source,  c = {})
      @temporary_path = source
      @config = c

      @target = target
      FileUtils.mkdir_p(target)

      @plugins = create_plugins(plugins)
    end

    def create_plugins(plugins)
      plugin_names = plugins == :all ?  retrieve_all_plugins : Array(plugins)
      plugin_names.map do |name|
        if skip_plugin?(name)
          puts "#{name} > #{Util.yellow("IGNORED")}"
          nil
        else
          Plugin.new(name, temporary_path)
        end
      end.compact
    end

    def retrieve_all_plugins
      plugins = []
      Octokit.auto_paginate = true
      client = Octokit::Client.new
      client.organization_repositories(LOGSTASH_PLUGINS_ORGANIZATION).each do |repository|
        plugins << repository[:name]
      end
      plugins
    end

    def skip_plugin?(name)
      ignored_plugins.any? { |re| re.match(name) }
    end

    def ignored_plugins
      @ignored_plugins ||= config["ignore_plugins"].map { |item| Regexp.new(item) }
    end

    def generate
      puts "Processing, #{plugins.size} plugins: #{plugins.collect(&:name).join(", ")}"

      task_runner = TaskRunner.new

      # Since this process can be quite long, we allow people to interrupt it,
      # but we should at least dump the currents errors..
      Stud.trap("INT") do
        puts "Process interrupted"
        task_runner.report_failures

        exit(1) # assume something went wrong
      end

      plugins.each do |plugin|
        task_runner.run(plugin.name) do
          plugin.generate(@target)
        end
      end

      task_runner.report_failures
    end
  end
end end
