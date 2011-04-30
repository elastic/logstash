#!/usr/bin/env ruby

require "erb"

if ARGV.size != 1
  $stderr.puts "No path given to search for plugin docs"
  $stderr.puts "Usage: #{$0} plugin_doc_dir"
  exit 1
end

basedir = ARGV[0]
docs = {
  "inputs" => Dir.glob(File.join(basedir, "inputs/*.html")),
  "filters" => Dir.glob(File.join(basedir, "filters/*.html")),
  "outputs" => Dir.glob(File.join(basedir, "outputs/*.html")),
}

template_path = File.join(File.dirname(__FILE__), "index.html.erb")
template = File.new(template_path).read
erb = ERB.new(template, nil, "-")
puts erb.result(binding)
