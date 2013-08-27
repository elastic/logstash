#!/usr/bin/env ruby

require "erb"

if ARGV.size != 1
  $stderr.puts "No path given to search for plugin docs"
  $stderr.puts "Usage: #{$0} plugin_doc_dir"
  exit 1
end

def plugins(glob)
  files = Dir.glob(glob)
  names = files.collect { |f| File.basename(f).gsub(".html", "") }
  return names.sort
end # def plugins

basedir = ARGV[0]
docs = {
  "inputs" => plugins(File.join(basedir, "inputs/*.html")),
  "codecs" => plugins(File.join(basedir, "codecs/*.html")),
  "filters" => plugins(File.join(basedir, "filters/*.html")),
  "outputs" => plugins(File.join(basedir, "outputs/*.html")),
}

template_path = File.join(File.dirname(__FILE__), "index.html.erb")
template = File.new(template_path).read
erb = ERB.new(template, nil, "-")
puts erb.result(binding)
