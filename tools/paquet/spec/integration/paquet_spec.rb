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

require "bundler"
require "fileutils"
require "stud/temporary"

describe "Pack the dependencies", :integration => true do
  let(:path) { File.expand_path(File.join(File.dirname(__FILE__), "..", "support")) }
  let(:vendor_path) { Stud::Temporary.pathname }
  let(:dependencies_path) { File.join(path, "dependencies") }
  let(:bundler_cmd) { "bundle install --path #{vendor_path}"}
  let(:rake_cmd) { "bundler exec rake paquet:vendor" }
  let(:bundler_config) { File.join(path, ".bundler") }
  let(:cache_path) { File.join(path, "cache") }
  let(:cache_flores_gem) { File.join(cache_path, "flores-0.0.6.gem")}
  let(:dummy_checksum_content) { "hello world" }

  before do
    FileUtils.mkdir_p(cache_path)
  end

  context "with gems in cache" do
    before do
      File.open(cache_flores_gem, "w") { |f| f.write(dummy_checksum_content) }

      FileUtils.rm_rf(bundler_config)
      FileUtils.rm_rf(vendor_path)

      Bundler.with_unbundled_env do
        Dir.chdir(path) do
          system(bundler_cmd)
          system(rake_cmd)
        end
      end
    end

    after do
      FileUtils.rm_rf(cache_flores_gem)
    end

    it "download the dependencies" do
      downloaded_dependencies = Dir.glob(File.join(dependencies_path, "*.gem"))

      expect(downloaded_dependencies.size).to eq(2)
      expect(downloaded_dependencies).to include(/flores-0\.0\.6/, /stud/)
      expect(downloaded_dependencies).not_to include(/logstash-devutils/)

      expect(File.read(Dir.glob(File.join(dependencies_path, "flores*.gem")).first)).to eq(dummy_checksum_content)
    end
  end

  context "without cached gems" do
    before do
      FileUtils.rm_rf(bundler_config)
      FileUtils.rm_rf(vendor_path)

      Bundler.with_unbundled_env do
        Dir.chdir(path) do
          system(bundler_cmd)
          system(rake_cmd)
        end
      end
    end

    it "download the dependencies" do
      downloaded_dependencies = Dir.glob(File.join(dependencies_path, "*.gem"))

      expect(downloaded_dependencies.size).to eq(2)
      expect(downloaded_dependencies).to include(/flores-0\.0\.6/, /stud/)
      expect(downloaded_dependencies).not_to include(/logstash-devutils/)

      expect(File.read(Dir.glob(File.join(dependencies_path, "flores*.gem")).first)).not_to eq(dummy_checksum_content)
    end
  end
end
