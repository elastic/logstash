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

require_relative "../../framework/fixture"
require_relative "../../framework/settings"
require_relative "../../services/logstash_service"
require_relative "../../framework/helpers"
require "logstash/devutils/rspec/spec_helper"
require "stud/temporary"
require "fileutils"
require "open3"

def gem_in_lock_file?(pattern, lock_file)
  content = File.read(lock_file)
  content.match(pattern)
end

# Bundler can mess up installation successful output: https://github.com/elastic/logstash/issues/15801
INSTALL_SUCCESS_RE = /IB?nstall successful/
INSTALLATION_SUCCESS_RE = /IB?nstallation successful/

describe "CLI > logstash-plugin install" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
    @logstash_plugin = @logstash.plugin_cli
    @pack_directory =  File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "logstash-dummy-pack"))
  end

  shared_examples "install from a pack" do
    let(:pack) { "file://#{File.join(@pack_directory, "logstash-dummy-pack.zip")}" }
    let(:install_command) { "bin/logstash-plugin install" }
    let(:change_dir) { true }

    # When you are on anything by linux we won't disable the internet with seccomp
    if RbConfig::CONFIG["host_os"] == "linux"
      context "without internet connection (linux seccomp wrapper)" do
        let(:offline_wrapper_path) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "offline_wrapper")) }

        before do
          Dir.chdir(offline_wrapper_path) do
            system("make clean")
            stdout_str, stderr_str, status = Open3.capture3("make")
            unless status.success?
              puts "ERROR in compiling 'offline' tool"
              puts "STDOUT: #{stdout_str}"
              puts "STDERR: #{stderr_str}"
            end
            expect(status.success?).to be(true)
          end
        end

        let(:offline_wrapper_cmd) { File.join(offline_wrapper_path, "offline") }

        it "successfully install the pack" do
          execute = @logstash_plugin.run_raw("#{offline_wrapper_cmd} #{install_command} #{pack}", change_dir)

          expect(execute.stderr_and_stdout).to match(INSTALL_SUCCESS_RE)
          expect(execute.exit_code).to eq(0)

          installed = @logstash_plugin.list("logstash-output-secret")
          expect(installed.stderr_and_stdout).to match(/logstash-output-secret/)

          expect(gem_in_lock_file?(/gemoji/, @logstash.lock_file)).to be_truthy
        end
      end
    else

      context "with internet connection" do
        it "successfully install the pack" do
          execute = @logstash_plugin.run_raw("#{install_command} #{pack}", change_dir)

          expect(execute.stderr_and_stdout).to match(INSTALL_SUCCESS_RE)
          expect(execute.exit_code).to eq(0)

          installed = @logstash_plugin.list("logstash-output-secret")
          expect(installed.stderr_and_stdout).to match(/logstash-output-secret/)

          expect(gem_in_lock_file?(/gemoji/, @logstash.lock_file)).to be_truthy
        end
      end
    end
  end

  context "pack" do
    context "when the command is run in the `$LOGSTASH_HOME`" do
      include_examples "install from a pack"
    end

    context "when the command is run outside of the `$LOGSTASH_HOME`" do
      include_examples "install from a pack" do
        let(:change_dir) { false }
        let(:install_command) { "#{@logstash.logstash_home}/bin/logstash-plugin install" }

        before :all do
          @current = Dir.pwd
          tmp = Stud::Temporary.pathname
          FileUtils.mkdir_p(tmp)
          Dir.chdir(tmp)
        end

        after :all do
          Dir.chdir(@current)
        end
      end
    end

    context "install non bundle plugin" do
      let(:plugin_name) { "logstash-input-github" }
      let(:install_command) { "bin/logstash-plugin install" }

      after(:each) do
         # cleanly remove the installed plugin to don't pollute
         # the environment for other subsequent tests
         removal = @logstash_plugin.run_raw("bin/logstash-plugin uninstall #{plugin_name}")

         expect(removal.stderr_and_stdout).to match(/Successfully removed #{plugin_name}/)
         expect(removal.exit_code).to eq(0)
      end

      it "successfully install the plugin" do
        execute = @logstash_plugin.run_raw("#{install_command} #{plugin_name}")

        expect(execute.stderr_and_stdout).to match(INSTALLATION_SUCCESS_RE)
        expect(execute.exit_code).to eq(0)

        installed = @logstash_plugin.list(plugin_name)
        expect(installed.stderr_and_stdout).to match(/#{plugin_name}/)
      end

      it "successfully installs the plugin with debug enabled" do
        execute = @logstash_plugin.run_raw("#{install_command} #{plugin_name}", true, {"DEBUG" => "1"})

        expect(execute.stderr_and_stdout).to match(INSTALLATION_SUCCESS_RE)
        expect(execute.exit_code).to eq(0)

        installed = @logstash_plugin.list(plugin_name)
        expect(installed.stderr_and_stdout).to match(/#{plugin_name}/)
      end
    end
  end
end
