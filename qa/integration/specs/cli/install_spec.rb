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
require_relative "pluginmanager_spec_helper"
require "logstash/devutils/rspec/spec_helper"
require "stud/temporary"
require "fileutils"
require "open3"

def gem_in_lock_file?(pattern, lock_file)
  content = File.read(lock_file)
  content.match(pattern)
end

def plugin_filename_re(name, version)
  %Q(\b#{Regexp.escape name}-#{Regexp.escape version}(-java)?\b)
end

# Bundler can mess up installation successful output: https://github.com/elastic/logstash/issues/15801
INSTALL_SUCCESS_RE = /IB?nstall successful/
INSTALLATION_SUCCESS_RE = /IB?nstallation successful/

INSTALLATION_ABORTED_RE = /Installation aborted/

describe "CLI > logstash-plugin install" do
  before(:each) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
    @logstash_plugin = @logstash.plugin_cli
  end

  shared_examples "install from a pack" do
    let(:pack) { "file://#{File.join(@pack_directory, "logstash-dummy-pack.zip")}" }
    let(:install_command) { "bin/logstash-plugin install" }
    let(:change_dir) { true }

    before(:all) do
      @pack_directory =  File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "logstash-dummy-pack"))
    end

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
    end

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

  context "pack", :skip_fips do
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

    context "install non bundle plugin", :skip_fips do
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

  context "rubygems hosted plugin", :skip_fips do
    include_context "pluginmanager validation helpers"
    shared_context("install over existing") do
      before(:each) do
        aggregate_failures("precheck") do
          expect("#{plugin_name}-#{existing_plugin_version}").to_not be_installed_gem
          expect("#{plugin_name}").to_not be_installed_gem
        end
        aggregate_failures("setup") do
          execute = @logstash_plugin.install(plugin_name, version: existing_plugin_version)

          expect(execute.stderr_and_stdout).to match(INSTALLATION_SUCCESS_RE)
          expect(execute.exit_code).to eq(0)

          expect("#{plugin_name}-#{existing_plugin_version}").to be_installed_gem
          expect(plugin_name).to be_in_gemfile.with_requirements(existing_plugin_version)
        end
      end
    end
    shared_examples("overwriting existing with explicit version") do
      include_context "install over existing"
      it "installs the specified version and removes the pre-existing one" do
        execute = @logstash_plugin.install(plugin_name, version: specified_plugin_version)

        aggregate_failures("command execution") do
          expect(execute.stderr_and_stdout).to match(INSTALLATION_SUCCESS_RE)
          expect(execute.exit_code).to eq(0)
        end

        installed = @logstash_plugin.list(plugin_name, verbose: true)
        expect(installed.stderr_and_stdout).to match(/#{Regexp.escape plugin_name} [(]#{Regexp.escape(specified_plugin_version)}[)]/)

        expect("#{plugin_name}-#{existing_plugin_version}").to_not be_installed_gem
        expect("#{plugin_name}-#{specified_plugin_version}").to be_installed_gem
      end
    end

    context "when installing over an older version using --version" do
      let(:plugin_name) { "logstash-filter-qatest" }
      let(:existing_plugin_version) { "0.1.0" }
      let(:specified_plugin_version) { "0.1.1" }

      include_examples "overwriting existing with explicit version"
    end

    context "when installing over a newer version using --version" do
      let(:plugin_name) { "logstash-filter-qatest" }
      let(:existing_plugin_version) { "0.1.0" }
      let(:specified_plugin_version) { "0.1.1" }

      include_examples "overwriting existing with explicit version"
    end

    context "when installing over existing without --version" do
      let(:plugin_name) { "logstash-filter-qatest" }
      let(:existing_plugin_version) { "0.1.0" }

      include_context "install over existing"

      context "with --preserve" do
        it "succeeds without changing the requirements in the Gemfile" do
          execute = @logstash_plugin.install(plugin_name, preserve: true)

          aggregate_failures("command execution") do
            expect(execute.stderr_and_stdout).to match(INSTALLATION_SUCCESS_RE)
            expect(execute.exit_code).to eq(0)
          end

          installed = @logstash_plugin.list(verbose: true)
          expect(installed.stderr_and_stdout).to match(/#{Regexp.escape plugin_name}/)

          # we want to ensure that the act of installing an already-installed plugin
          # does not change its requirements in the gemfile, and leaves the previously-installed
          # version in-tact.
          expect(plugin_name).to be_in_gemfile.with_requirements(existing_plugin_version)
          expect("#{plugin_name}-#{existing_plugin_version}").to be_installed_gem
        end
      end

      context "without --preserve" do
        # this spec is OBSERVED behaviour, which I believe to be undesirable.
        it "succeeds and removes the version requirement from the Gemfile" do
          execute = @logstash_plugin.install(plugin_name)

          aggregate_failures("command execution") do
            expect(execute.stderr_and_stdout).to match(INSTALLATION_SUCCESS_RE)
            expect(execute.exit_code).to eq(0)
          end

          installed = @logstash_plugin.list(plugin_name, verbose: true)
          expect(installed.stderr_and_stdout).to match(/#{Regexp.escape plugin_name}/)

          # This is the potentially-undesirable surprising behaviour, specified here
          # as a means of documentation, not a promise of future behavior.
          expect(plugin_name).to be_in_gemfile.without_requirements

          # we expect _a_ version of the plugin to be installed, but cannot be opinionated
          # about which version was installed because bundler won't necessarily re-resolve
          # the dependency graph to get us an upgrade since the no-requirements dependency
          # is still met (but it MAY do so if also installing plugins that are not present).
          expect("#{plugin_name}").to be_installed_gem
        end
      end
    end

    context "installing plugin that isn't present" do
      it "installs the plugin" do
        aggregate_failures("prevalidation") do
          expect("logstash-filter-qatest").to_not be_installed_gem
        end

        execute = @logstash_plugin.install("logstash-filter-qatest")

        expect(execute.stderr_and_stdout).to match(INSTALLATION_SUCCESS_RE)
        expect(execute.exit_code).to eq(0)

        installed = @logstash_plugin.list("logstash-filter-qatest")
        expect(installed.stderr_and_stdout).to match(/logstash-filter-qatest/)
        expect(installed.exit_code).to eq(0)

        expect(gem_in_lock_file?(/logstash-filter-qatest/, @logstash.lock_file)).to be_truthy

        expect("logstash-filter-qatest").to be_installed_gem
      end
    end
    context "installing plugin that doesn't exist on rubygems" do
      it "doesn't install anything" do
        execute = @logstash_plugin.install("logstash-filter-404-no-exist")

        expect(execute.stderr_and_stdout).to match(INSTALLATION_ABORTED_RE)
        expect(execute.exit_code).to eq(1)
      end
    end
    context "installing gem that isn't a plugin" do
      it "doesn't install anything" do
        execute = @logstash_plugin.install("dummy_gem")

        expect(execute.stderr_and_stdout).to match(INSTALLATION_ABORTED_RE)
        expect(execute.exit_code).to eq(1)
      end
    end
  end
end
