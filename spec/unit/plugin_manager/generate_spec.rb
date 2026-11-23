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

require "spec_helper"
require "pluginmanager/main"
require "pluginmanager/generate"
require "stud/temporary"
require "fileutils"

describe LogStash::PluginManager::Generate do
  let(:templates_dir) { File.expand_path("../../../lib/pluginmanager/templates", __dir__) }

  it "has no symlinks in the plugin templates" do
    symlinks = Dir.glob(File.join(templates_dir, "**", "*"), File::FNM_DOTMATCH).select { |f| File.symlink?(f) }
    expect(symlinks).to be_empty
  end

  described_class::TYPES.each do |type|
    context "with --type #{type}" do
      let(:path) { Stud::Temporary.directory }
      let(:plugin_dir) { File.join(path, "logstash-#{type}-example") }
      let(:template_files) do
        source = File.join(templates_dir, "#{type}-plugin")
        Dir.glob(File.join(source, "**", "*"), File::FNM_DOTMATCH)
           .reject { |f| File.directory?(f) }
           .map { |f| f.sub("#{source}/", "").sub(/\.erb\z/, "") }
      end

      after { FileUtils.rm_rf(path) }

      it "generates a plugin containing every template file" do
        cmd = described_class.new("generate")
        expect { cmd.run(["--type", type, "--name", "example", "--path", path]) }.not_to raise_error

        generated = Dir.glob(File.join(plugin_dir, "**", "*"), File::FNM_DOTMATCH)
                       .reject { |f| File.directory?(f) }
                       .map { |f| f.sub("#{plugin_dir}/", "") }
        expect(generated).to match_array(template_files)
        expect(File).to exist(File.join(plugin_dir, "logstash-#{type}-example.gemspec"))
      end
    end
  end
end
