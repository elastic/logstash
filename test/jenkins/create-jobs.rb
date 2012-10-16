#!/usr/bin/env ruby

require "erb"

if ENV["JENKINS_HOME"].nil?
  puts "No JENKINS_HOME set."
  exit 1
end

plugindir = File.join(File.dirname(__FILE__), "..", "..", "lib", "logstash")

plugins = %w(inputs filters outputs).collect { |t| Dir.glob(File.join(plugindir, t, "*.rb")) }.flatten

template = ERB.new(File.read(File.join(File.dirname(__FILE__), "config.xml.erb")))
plugins.each do |path|
  job = path.gsub(/.*\/([^\/]+)\/([^\/]+)\.rb$/, 'plugin.\1.\2')
  plugin_path = path.gsub(/.*\/([^\/]+)\/([^\/]+)$/, '\1/\2')

  jobdir = File.join(ENV["JENKINS_HOME"], "jobs", job)
  puts "Writing #{jobdir}/config.xml"
  Dir.mkdir(jobdir) if !Dir.exists?(jobdir)
  File.write(File.join(jobdir, "config.xml"), template.result(binding))
end
