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

require_relative '../../framework/fixture'
require_relative '../../framework/settings'
require_relative '../../services/logstash_service'
require_relative '../../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

require "bundler/lockfile_parser"

describe "CLI > logstash-plugin clean" do

  let(:fixture) { Fixture.new(__FILE__) }
  let(:logstash) { fixture.get_service("logstash") }
  let(:gem_vendor_path) { (Pathname.new(logstash.logstash_home) / "vendor" / "bundle" / "jruby").glob("[0-9]*").first }

  subject(:logstash_plugin) { logstash.plugin_cli }

  ## inspects the Gemfile.lock to get a mapping of active gems
  # @return [Hash{String=>String}]
  def activated_gems
    ::Bundler::LockfileParser.new(File.read(logstash.lock_file)).specs.each_with_object({}) do |spec, memo|
      memo[spec.name] = spec.version.to_s
    end
  end

  def find_vendored_gemspecs(gem_name)
    (gem_vendor_path / "specifications").glob("#{gem_name}-[0-9]*.gemspec")
  end

  def find_vendored_gem_files(gem_name)
    (gem_vendor_path / "gems").glob("#{gem_name}-[0-9]*")
  end


  context "when run after removing a plugin with many gem dependencies" do
    # we uninstall the AWS integration plugin, because we know that it brings a number of extra dependencies
    # and we validate in the `before` bock that the regular `remove` operation successfully _deactivates_ those
    # gems but that they are still present on disk
    before(:each) do
      aggregate_failures("setup") do
        activated_gems_pre_removal = activated_gems.freeze

        logstash_plugin.remove("logstash-integration-aws")

        activated_gems_post_removal = activated_gems.freeze

        # ensure that we have actually deactivated some gems, including known aws-integration dependencies
        @deactivated_gems = activated_gems_pre_removal.keys - activated_gems_post_removal.keys
        expect(@deactivated_gems).to_not be_empty
        expect(@deactivated_gems).to include("logstash-integration-aws"), lambda { "expected `logstash-integration-aws` gems to not be in the active set after plugin removal: #{activated_gems_post_removal}" }
        expect(@deactivated_gems).to include("aws-sdk-core"), lambda { "expected AWS-related gems dependencies to not be in the active set after plugin removal: #{activated_gems_post_removal}" }

        # we expect the gemspecs and expanded gems to still be present before a `clean`
        @deactivated_gems.each do |deactivated_gem|
          expect(find_vendored_gemspecs(deactivated_gem)).to_not be_empty, lambda { "expected remaining gemspec for `#{deactivated_gem}` after normal removal"}
          expect(find_vendored_gem_files(deactivated_gem)).to_not be_empty, lambda { "expected remaining gem files for `#{deactivated_gem}` after normal removal"}
        end
      end
    end

    it "successfully removes the deactivated plugins and orphaned dependencies from disk" do
      logstash_plugin.clean

      aggregate_failures do
        @deactivated_gems.each do |gem_name|
          find_vendored_gemspecs(gem_name).tap do |found_vendored_gemspecs|
            expect(find_vendored_gemspecs(gem_name)).to be_empty, lambda { "expected gemspecs for `#{gem_name}` to NOT be present after being cleaned (found: `#{found_vendored_gemspecs}`)"}
          end
          find_vendored_gem_files(gem_name).tap do |found_vendored_gem_files|
            expect(found_vendored_gem_files).to be_empty, lambda { "expected gem files for` #{gem_name}` to NOT be present after being cleaned (found: `#{found_vendored_gem_files}`"}
          end
        end
      end
    end
  end
end
