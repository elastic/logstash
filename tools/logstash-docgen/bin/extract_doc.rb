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

require "fileutils"

# This scripts take the output result of the `logstash-docgen` and create the PR to the plugin repositoring
# its a bit of a hack and is designed to be run one time.

TARGET = File.expand_path(File.join(File.dirname(__FILE__), "..", "target", "**", "*.asciidoc"))

PR_TARGET = File.expand_path(File.join(File.dirname(__FILE__), "..", "pr_target"))
WILDCARDS_FILE = '.files = Dir["lib/**/*","spec/**/*","*.gemspec","*.md","CONTRIBUTORS","Gemfile","LICENSE","NOTICE.TXT", "vendor/jar-dependencies/**/*.jar", "vendor/jar-dependencies/**/*.rb", "VERSION", "docs/**/*"]'

FileUtils.mkdir_p(PR_TARGET)

FileUtils.touch(File.join(PR_TARGET, "pr-logs"))

Dir.glob(TARGET) do |f|
  file = File.basename(f)
  plugin_name = File.basename(f, ".asciidoc")
  parts = f.split("/")
  type = parts[-2].gsub(/s$/, '')

  next if type =~ /mixin/

  Dir.chdir(PR_TARGET) do
    plugin_target = "logstash-#{type}-#{plugin_name}"
    puts("hub clone logstash-plugins/#{plugin_target}")
    system("hub clone logstash-plugins/#{plugin_target}")

    Dir.chdir(plugin_target) do
      FileUtils.mkdir_p("docs")
      FileUtils.cp(f, "docs/index.asciidoc")

      gemspec_file = "./#{plugin_target}.gemspec"
      gemspec = File.read(gemspec_file)
      gemspec.gsub!(/\.files\s=.+/, WILDCARDS_FILE)

      IO.write(gemspec_file, gemspec)

      system("hub checkout -b docs/extraction")
      system("hub add docs")
      system("hub add *.gemspec")
      system("hub commit -am 'Initial doc move'")
      system("hub push origin docs/extraction")
      system("hub pull-request -F ../../docs.md > ../pr-logs")
    end
  end
end
