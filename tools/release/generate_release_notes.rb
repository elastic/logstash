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

RELEASE_NOTES_PATH = "docs/static/releasenotes.asciidoc"
release_branch = ARGV[0]
previous_release_tag = ARGV[1]
report = []

`git checkout #{release_branch}`

current_release = YAML.load(IO.read("versions.yml"))["logstash"]
current_release_dashes = current_release.tr(".", "-")

release_notes = IO.read(RELEASE_NOTES_PATH).split("\n")

release_notes.insert(5, "* <<logstash-#{current_release_dashes},Logstash #{current_release}>>")

release_notes_entry_index = release_notes.find_index {|line| line.match(/^\[\[logstash/) }

report << "[[logstash-#{current_release_dashes}]]"
report << "=== Logstash #{current_release} Release Notes\n"

plugin_changes = {}

report <<  "---------- DELETE FROM HERE ------------"
report <<  "=== Logstash Pull Requests with label v#{current_release}\n"

uri = URI.parse("https://api.github.com/search/issues?q=repo:elastic/logstash+is:pr+is:closed+label:v#{current_release}&sort=created&order=asc")
pull_requests = JSON.parse(Net::HTTP.get(uri))
pull_requests['items'].each do |prs|
  report << "* #{prs['title']} #{prs['html_url']}[##{prs['number']}]"
end
report << ""

report <<  "=== Logstash Commits between #{release_branch} and #{previous_release_tag}\n"
report <<  "Computed with \"git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v#{previous_release_tag}..#{release_branch}\""
report <<  ""
logstash_prs =  `git log --pretty=format:'%h -%d %s (%cr) <%an>' --abbrev-commit --date=relative v#{previous_release_tag}..#{release_branch}`
report <<  logstash_prs
report << "\n=== Logstash Plugin Release Changelogs ==="
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
report << "---------- DELETE UP TO HERE ------------\n"

report << "==== Plugins\n"

plugin_changes.each do |plugin, versions|
  _, type, name = plugin.split("-")
  header = "*#{name.capitalize} #{type.capitalize}*"
  start_changelog_file = Tempfile.new(plugin + 'start')
  end_changelog_file = Tempfile.new(plugin + 'end')
  changelog = `curl https://raw.githubusercontent.com/logstash-plugins/#{plugin}/v#{versions.last}/CHANGELOG.md`.split("\n")
  report << "#{header}\n"
  changelog.each do |line|
    break if line.match(/^## #{versions.first}/)
    next if line.match(/^##/)
    line.gsub!(/^\+/, "")
    line.gsub!(/ #(?<number>\d+)\s*$/, " https://github.com/logstash-plugins/#{plugin}/issues/\\k<number>[#\\k<number>]")
    line.gsub!(/^\s+-/, "*")
    report << line
  end
  report << ""
  start_changelog_file.unlink
  end_changelog_file.unlink
end

release_notes.insert(release_notes_entry_index, report.join("\n").gsub(/\n{3,}/, "\n\n"))

IO.write(RELEASE_NOTES_PATH, release_notes.join("\n"))

puts "Creating commit.."
branch_name = "update_release_notes_#{Time.now.to_i}"
`git checkout -b #{branch_name}`
`git commit docs/static/releasenotes.asciidoc -m "Update release notes for #{current_release}"`

puts "Pushing commit.."
`git remote add upstream git@github.com:elastic/logstash.git`
`git push upstream #{branch_name}`

puts "Creating Pull Request"
pr_title = "Release notes draft for #{current_release}"
`curl -H "Authorization: token #{ENV['GITHUB_TOKEN']}" -d '{"title":"#{pr_title}","base":"#{ENV['branch_specifier']}", "head":"#{branch_name}"}' https://api.github.com/repos/elastic/logstash/pulls`

puts "Done"
