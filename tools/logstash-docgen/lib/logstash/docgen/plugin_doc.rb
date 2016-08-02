# encoding: utf-8
require "logstash/docgen/parser"
require "stud/temporary"

namespace :doc do
  desc "Preview the raw HTML of the documentation"
  task :html do
    puts generate_preview({ :raw => false })
  end

  desc "Preview Asciidoc documentation"
  task :asciidoc do
    puts generate_preview
  end
end

task :doc => "doc:html"


def generate_preview(options = {})
  LogStash::Docgen.generate_for_plugin(Dir.pwd, options).output
end
