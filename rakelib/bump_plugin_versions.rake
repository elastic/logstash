require 'net/http'
require 'uri'
require 'fileutils'

def compute_dependecy(version, allow_for)
  major, minor, patch = Gem::Version.new(version).release.segments
  case allow_for
  when "major"
    then "~> #{major}"
  when "minor"
    then "~> #{major}.#{minor}"
  when "patch"
    then "~> #{major}.#{minor}.#{patch}"
  end
end

task :bump_versions, [:version, :allow_for] => [] do |t, args|
  base_logstash_version = args[:version]
  if ["major", "minor", "patch"].include?(args[:allow_for])
    allow_bump_for = args[:allow_for]
  else
    puts "second argument must be one of 'major', 'minor' or 'patch', got '#{args[:allow_for]}'"
    exit(1)
  end

  puts "Computing #{allow_bump_for} plugin dependency bump from #{base_logstash_version}.."

  puts "Fetching lock file for #{base_logstash_version}.."
  uri = URI.parse("https://raw.githubusercontent.com/elastic/logstash/v#{base_logstash_version}/Gemfile.jruby-2.5.lock.release")
  result = Net::HTTP.get(uri)

  base_plugin_versions = {}
  skip_elements = ["logstash-core", "logstash-devutils", "logstash-core-plugin-api"]
  result.split("\n").each do |line|
    # match e.g. "    logstash-output-nagios (3.0.6)"
    if match = line.match(/^    (?<plugin>logstash-.+?)\s\((?<version>.+?)(?:-java)?\)/)
      next if skip_elements.include?(match["plugin"])
      base_plugin_versions[match["plugin"]] = match["version"]
    end
  end

  computed_dependency = {}
  puts "Generating new Gemfile.template file with computed dependencies"
  gemfile = IO.read("Gemfile.template")
  base_plugin_versions.each do |plugin, version|
    dependency = compute_dependecy(version, allow_bump_for)
    gemfile.gsub!(/"#{plugin}".*$/, "\"#{plugin}\", \"#{dependency}\"")
  end

  IO.write("Gemfile.template", gemfile)

  puts "Cleaning up before running 'rake artifact:tar'"
  FileUtils.rm_f("Gemfile")
  FileUtils.rm_f("Gemfile.jruby-2.5.lock.release")
  FileUtils.rm_rf("vendor")

  # compute new lock file
  puts "Running 'rake artifact:tar'"
  result = `rake artifact:tar`

  puts "Cleaning up generated lock file (removing injected requirements)"
  # remove explicit requirements from lock file
  lock_file = IO.read("Gemfile.lock")
  new_lock = []
  lock_file.split("\n").each do |line|
    new_lock << line.gsub(/^  (?<plugin>logstash-\w+-.+?) .+?$/, "  \\k<plugin>")
  end
  IO.write("Gemfile.lock", new_lock.join("\n"))

  # rename file
  puts "Finishing up.."
  FileUtils.mv("Gemfile.lock", "Gemfile.jruby-2.5.lock.release")

  `git checkout -- Gemfile.template`
  puts "Done"

  puts `git diff`
end
