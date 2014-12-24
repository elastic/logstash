#!/usr/bin/env ruby

require "erb"

if ARGV.size != 2
  $stderr.puts "No path given to search for plugin docs"
  $stderr.puts "Usage: #{$0} plugin_doc_dir type"
  exit 1
end


def plugins(glob)
  plugins=Hash.new []
  files = Dir.glob(glob)
  files.collect { |f| File.basename(f).gsub(".asciidoc", "") }.each {|plugin|
    first_letter = plugin[0,1]
    plugins[first_letter] += [plugin]
  }
  return Hash[plugins.sort]
end # def plugins

basedir = ARGV[0]
type = ARGV[1]

docs = plugins(File.join(basedir, "#{type}/*.asciidoc"))
template_path = File.join(File.dirname(__FILE__), "index-#{type}.asciidoc.erb")
template = File.new(template_path).read
erb = ERB.new(template, nil, "-")

path = "#{basedir}/#{type}.asciidoc"

File.open(path, "w") do |out|
  html = erb.result(binding)
  out.puts(html)
end
