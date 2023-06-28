#!/usr/bin/env ruby
# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require 'net/http'
require 'uri'
require 'fileutils'
require 'yaml'
require 'optparse'

options = {pr: true}
OptionParser.new do |opts|
  opts.banner = <<~EOBANNER
   Usage: bump_plugin_versions.rb base_branch last_release allow_for --[no-]pr

   If you have a local lockfile, you can specify "LOCAL" for last_release to
   use it as your baseline. This allows you to consume patch releases on a
   minor release after feature freeze and the initial minor updates.

  EOBANNER

  opts.on("--[no-]pr", "Create Pull Request") do |v|
    options[:pr] = v
  end
end.parse!

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

if base_logstash_version == "LOCAL"
  puts "Using local lockfile..."
  begin
    result = File.read("Gemfile.jruby-3.1.lock.release")
  rescue => e
    puts "Failed to read local lockfile #{e}"
    exit(1)
  end
else
  puts "Fetching lock file for #{base_logstash_version}.."
  uri = URI.parse("https://raw.githubusercontent.com/elastic/logstash/v#{base_logstash_version}/Gemfile.jruby-3.1.lock.release")
  result = Net::HTTP.get(uri)
  if result.match(/404/)
    puts "Lock file or git tag for #{base_logstash_version} not found. Aborting"
    exit(1)
  end
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

puts "Cleaning up before running computing dependencies"
FileUtils.rm_f("Gemfile.jruby-3.1.lock.release")

# compute new lock file
puts "Running: ./gradlew clean installDefaultGems"
`./gradlew clean installDefaultGems`

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
FileUtils.mv("Gemfile.lock", "Gemfile.jruby-3.1.lock.release")

`git checkout -- Gemfile.template`

puts `git diff Gemfile.jruby-3.1.lock.release`

exit(0) unless options[:pr]
puts "Creating commit.."

branch_name = "update_lock_#{Time.now.to_i}"
`git checkout -b #{branch_name}`
`git commit Gemfile.jruby-3.1.lock.release -m "Update #{allow_bump_for} plugin versions in gemfile lock"`

puts "Pushing commit.."
`git remote add upstream git@github.com:elastic/logstash.git`
`git push upstream #{branch_name}`

current_release = YAML.safe_load(IO.read("versions.yml"))["logstash"]
puts "Creating Pull Request"
pr_title = "bump lock file for #{current_release}"

`curl -H "Authorization: token #{ENV['GITHUB_TOKEN']}" -d '{"title":"#{pr_title}","base":"#{base_branch}", "head":"#{branch_name}"}' https://api.github.com/repos/elastic/logstash/pulls`
