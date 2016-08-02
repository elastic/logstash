# encoding: utf-8
require "fileutils"

DEFAULT_DOC_DIRECTORY = ::File.join(::File.dirname(__FILE__), "..", "build", "docs")

namespace "docs" do
  desc "Generate documentation for all plugins"
  task "generate" do
    Rake::Task['plugin:install-all'].invoke
    Rake::Task['docs:generate-plugins'].invoke
  end

  desc "Generate the doc for all the currently installed plugins"
  task "generate-plugins", [:output] do |t, args|
    args.with_defaults(:output => DEFAULT_DOC_DIRECTORY)

    require "bootstrap/environment"
    require "logstash-core/logstash-core"
    LogStash::Bundler.setup!({:without => [:build]})

    require "logstash/docgen/logstash_generator"

    FileUtils.mkdir_p(args[:output])
    exit(LogStash::Docgen::LogStashGenerator.new(args[:output]).generate_plugins_docs)
  end
end
