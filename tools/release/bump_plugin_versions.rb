#!/usr/bin/env ruby
# encoding: utf-8
require 'net/http'
require 'uri'
require 'fileutils'
require 'yaml'

def compute_dependecy(version, allow_for)
  gem_version = Gem::Version.new(version)
  return version if gem_version.prerelease?
  major, minor, patch = gem_version.release.segments
  case allow_for
  when "major"
    then "~> #{major}"
  when "minor"
    then "~> #{major}.#{minor}"
  when "patch"
    then "~> #{major}.#{minor}.#{patch}"
  end
end

base_branch = ARGV[0]
base_logstash_version = ARGV[1]
allow_bump_for = ARGV[2]

unless ["major", "minor", "patch"].include?(allow_bump_for)
  puts "second argument must be one of 'major', 'minor' or 'patch', got '#{allow_bump_for}'"
  exit(1)
end

puts "Computing #{allow_bump_for} plugin dependency bump from #{base_logstash_version}.."

puts "Fetching lock file for #{base_logstash_version}.."
uri = URI.parse("https://raw.githubusercontent.com/elastic/logstash/v#{base_logstash_version}/Gemfile.jruby-2.5.lock.release")
result = Net::HTTP.get(uri)
if result.match(/404/)
  puts "Lock file or git tag for #{base_logstash_version} not found. Aborting"
  exit(1)
end

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
  if gemfile.gsub!(/"#{plugin}".*$/, "\"#{plugin}\", \"#{dependency}\"").nil?
    gemfile << "gem \"#{plugin}\", \"#{dependency}\"\n"
  end
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

puts `git diff Gemfile.jruby-2.5.lock.release`

puts "Creating commit.."

branch_name = "update_lock_#{Time.now.to_i}"
`git checkout -b #{branch_name}`
`git commit Gemfile.jruby-2.5.lock.release -m "Update #{allow_bump_for} plugin versions in gemfile lock"`

puts "Pushing commit.."
`git remote add upstream git@github.com:elastic/logstash.git`
`git push upstream #{branch_name}`

current_release = YAML.safe_load(IO.read("versions.yml"))["logstash"]
puts "Creating Pull Request"
pr_title = "bump lock file for #{current_release}"

`curl -H "Authorization: token #{ENV['GITHUB_TOKEN']}" -d '{"title":"#{pr_title}","base":"#{base_branch}", "head":"#{branch_name}"}' https://api.github.com/repos/elastic/logstash/pulls`
