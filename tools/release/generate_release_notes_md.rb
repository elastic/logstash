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

# Example:
# ruby generate_release_notes.rb 6.4 6.4.1
#
# This:
# * compares the lock file of two commits
# * for each plugin version bumped show CHANGELOG.md of the bumped version
require 'tempfile'
require 'yaml'
require 'json'
require 'net/http'

RELEASE_NOTES_PATH = "docs/release-notes/index.md"
CHANGELOG_FRAGMENTS_PATH = "docs/changelog"

SECTION_ORDER = %w[feature enhancement bug breaking_change deprecation dependency doc].freeze
SECTION_LABELS = {
  "feature"        => "New features",
  "enhancement"    => "Enhancements",
  "bug"            => "Bug fixes",
  "breaking_change" => "Breaking changes",
  "deprecation"    => "Deprecations",
  "dependency"     => "Dependency updates",
  "doc"            => "Documentation",
}.freeze

release_branch = ARGV[0]
previous_release_tag = ARGV[1]
user = ARGV[2]
token = ARGV[3]
report = []

`git checkout #{release_branch}`

current_release = YAML.load(IO.read("versions.yml"))["logstash"]

release_notes = IO.read(RELEASE_NOTES_PATH).split("\n")

coming_tag_index = release_notes.find_index {|line| line.match(/^## #{current_release} \[logstash-#{current_release}-release-notes\]$/) }
coming_tag_index += 1 if coming_tag_index
release_notes_entry_index = coming_tag_index || release_notes.find_index {|line| line.match(/^## .*\[logstash-.*-release-notes\]$/) }

unless coming_tag_index
  report << "## #{current_release} [logstash-#{current_release}-release-notes]\n"
end

# Load changelog fragments and group by type
fragments = Dir.glob("#{CHANGELOG_FRAGMENTS_PATH}/*.yaml").sort.map do |path|
  YAML.safe_load(File.read(path), permitted_classes: [Integer])
rescue => e
  $stderr.puts "Warning: skipping #{path}: #{e.message}"
  nil
end.compact

highlights = fragments.select { |f| f['highlight']&.fetch('notable', false) }
unless highlights.empty?
  report << "### Highlights [logstash-#{current_release}-highlights]\n"
  highlights.each do |f|
    h = f['highlight']
    report << "#### #{h['title']}\n"
    report << h['body'].to_s
    report << ""
  end
end

by_type = fragments.group_by { |f| f['type'] }

SECTION_ORDER.each do |type|
  entries = by_type[type]
  next unless entries&.any?

  anchor = "logstash-#{current_release}-#{type.tr('_', '-')}"
  report << "### #{SECTION_LABELS[type]} [#{anchor}]\n"
  entries.sort_by { |f| f['pr'] }.each do |f|
    issue_links = Array(f['issues']).map { |i| "[##{i}](https://github.com/elastic/logstash/issues/#{i})" }.join(", ")
    suffix = issue_links.empty? ? "" : " (#{issue_links})"
    report << "* #{f['summary']} [##{f['pr']}](https://github.com/elastic/logstash/pull/#{f['pr']})#{suffix}"
  end
  report << ""
end

plugin_changes = {}

report <<  "---------- GENERATED CONTENT STARTS HERE ------------"
report <<  "=== Logstash Plugin Release Changelogs ==="
report << "Computed from \"git diff v#{previous_release_tag}..#{release_branch} *.release\""
result = `git diff v#{previous_release_tag}..#{release_branch} *.release`.split("\n")

result.each do |line|
  # example "+    logstash-input-syslog (3.4.1)"
  if match = line.match(/\+\s+(?<plugin>logstash-.+?-.+?)\s+\((?<version>\d+\.\d+.\d+).*?\)/)
    plugin_changes[match[:plugin]] ||= []
    plugin_changes[match[:plugin]] << match[:version]
  elsif match = line.match(/\-\s+(?<plugin>logstash-.+?-.+?)\s+\((?<version>\d+\.\d+.\d+).*?\)/)
    plugin_changes[match[:plugin]] ||= []
    plugin_changes[match[:plugin]].unshift(match[:version])
  else
    # ..
  end
end
report << "Changed plugin versions:"
plugin_changes.each {|p, v| report << "#{p}: #{v.first} -> #{v.last}" }
report << "---------- GENERATED CONTENT ENDS HERE ------------\n"

report << "### Plugins [logstash-plugin-#{current_release}-changes]\n"

plugin_changes.each do |plugin, versions|
  _, type, name = plugin.split("-")
  header = "**#{name.capitalize} #{type.capitalize} - #{versions.last}**"
  # Determine the correct GitHub organization
  org = plugin.include?('elastic_integration') ? 'elastic' : 'logstash-plugins'
  start_changelog_file = Tempfile.new(plugin + 'start')
  end_changelog_file = Tempfile.new(plugin + 'end')
  changelog = `curl https://raw.githubusercontent.com/#{org}/#{plugin}/v#{versions.last}/CHANGELOG.md`.split("\n")
  report << "#{header}\n"
  changelog.each do |line|
    break if line.match(/^## #{versions.first}/)
    next if line.match(/^##/)
    line.gsub!(/^\+/, "")
    line.gsub!(/ #(?<number>\d+)\s*$/, " https://github.com/#{org}/#{plugin}/issues/\\k<number>[#\\k<number>]")
    line.gsub!(/\[#(?<number>\d+)\]\((?<url>[^)]*)\)/, "[#\\k<number>](\\k<url>)")
    line.gsub!(/^\s+-/, "*")
    report << line
  end
  report << ""
  start_changelog_file.unlink
  end_changelog_file.unlink
end

release_notes.insert(release_notes_entry_index, report.join("\n").gsub(/\n{3,}/, "\n\n"))

IO.write(RELEASE_NOTES_PATH, release_notes.join("\n"))

if token.nil?
  puts "No token provided, skipping commit and push"
  exit
end

fragment_files = Dir.glob("#{CHANGELOG_FRAGMENTS_PATH}/*.yaml")
fragment_files.each { |f| File.delete(f) }

puts "Creating commit.."
branch_name = "update_release_notes_#{Time.now.to_i}"
`git checkout -b #{branch_name}`
files_to_commit = ([RELEASE_NOTES_PATH] + fragment_files).join(" ")
`git add #{files_to_commit}`
`git commit -m "Update release notes for #{current_release}"`

puts "Pushing commit.."
`git remote set-url origin https://x-access-token:#{token}@github.com/elastic/logstash.git`
`git push origin #{branch_name}`

puts "Creating Pull Request"
pr_title = "Release notes for #{current_release}"
result = `curl -H "Authorization: token #{token}" -d '{"title":"#{pr_title}","base":"#{release_branch}", "head":"#{branch_name}", "draft": true}' https://api.github.com/repos/elastic/logstash/pulls`
puts result
pr_number = JSON.parse(result)["number"]
puts `curl -X POST -H "Accept: application/vnd.github.v3+json" -H "Authorization: token #{token}" https://api.github.com/repos/elastic/logstash/issues/#{pr_number}/assignees -d '{"assignees":["#{user}"]}'`
puts "Done"
