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
require "logstash/runner"
require "stud/task"
require "stud/trap"
require "stud/temporary"
require "logstash/util/java_version"
require "logstash/config/source_loader"
require "logstash/config/modules_common"
require "logstash/modules/util"
require "logstash/elasticsearch_client"
require "json"
require "webmock/rspec"
require_relative "../support/helpers"
require_relative "../support/matchers"

describe LogStash::Runner do
  subject(:runner) { LogStash::Runner }
  let(:logger) { double("logger") }
  let(:agent) { double("agent") }

  before :each do
    clear_data_dir

    WebMock.disable_net_connect!(allow_localhost: true)

    allow(LogStash::Runner).to receive(:logger).and_return(logger)
    allow(logger).to receive(:debug?).and_return(true)
    allow(logger).to receive(:subscribe).with(any_args)
    allow(logger).to receive(:debug) {}
    allow(logger).to receive(:log) {}
    allow(logger).to receive(:info) {}
    allow(logger).to receive(:fatal) {}
    allow(logger).to receive(:warn) {}
    allow(LogStash::ShutdownWatcher).to receive(:logger).and_return(logger)
    allow(LogStash::Logging::Logger).to receive(:configure_logging) do |level, path|
      allow(logger).to receive(:level).and_return(level.to_sym)
    end
    allow(LogStash::Logging::Logger).to receive(:reconfigure).with(any_args)
    # Make sure we don't start a real pipeline here.
    # because we cannot easily close the pipeline
    allow(LogStash::Agent).to receive(:new).with(any_args).and_return(agent)
    allow(agent).to receive(:execute)
    allow(agent).to receive(:shutdown)
  end

  after(:each) do
    LogStash::SETTINGS.get_value("modules_list").clear
  end

  describe "argument precedence" do
    let(:config) { "input {} output {}" }
    let(:cli_args) { ["-e", config, "-w", "20"] }
    let(:settings_yml_hash) { { "pipeline.workers" => 2 } }

    before :each do
      allow(LogStash::SETTINGS).to receive(:read_yaml).and_return(settings_yml_hash)
    end

    it "favors the last occurence of an option" do
      expect(LogStash::Agent).to receive(:new) do |settings|
        expect(settings.get("config.string")).to eq(config)
        expect(settings.get("pipeline.workers")).to eq(20)
      end.and_return(agent)
      subject.run("bin/logstash", cli_args)
    end
  end

  describe "argument parsing" do
    subject { LogStash::Runner.new("") }

    context "when -e is given" do
      let(:args) { ["-e", "input {} output {}"] }
      let(:agent) { double("agent") }

      before do
        allow(agent).to receive(:shutdown)
      end

      it "should execute the agent" do
        expect(subject).to receive(:create_agent).and_return(agent)
        expect(agent).to receive(:execute).once
        subject.run(args)
      end
    end
  end

  context "--pluginpath" do
    subject { LogStash::Runner.new("") }
    let(:valid_directory) { Stud::Temporary.directory }
    let(:invalid_directory) { "/a/path/that/doesnt/exist" }
    let(:multiple_paths) { [Stud::Temporary.directory, Stud::Temporary.directory] }

    it "should pass -p contents to the configure_plugin_paths method" do
      args = ["-p", valid_directory]
      expect(subject).to receive(:configure_plugin_paths).with([valid_directory])
      expect { subject.run(args) }.to_not raise_error
    end

    it "should add single valid dir path to the environment" do
      expect(LogStash::Environment).to receive(:add_plugin_path).with(valid_directory)
      subject.configure_plugin_paths(valid_directory)
    end

    it "should fail with single invalid dir path" do
      expect(LogStash::Environment).not_to receive(:add_plugin_path)
      expect {subject.configure_plugin_paths(invalid_directory)}.to raise_error(Clamp::UsageError)
    end

    it "should add multiple valid dir path to the environment" do
      multiple_paths.each {|path| expect(LogStash::Environment).to receive(:add_plugin_path).with(path)}
      subject.configure_plugin_paths(multiple_paths)
    end
  end

  context "--auto-reload" do
    subject { LogStash::Runner.new("") }
    context "when -e is given" do
      let(:args) { ["-r", "-e", "input {} output {}"] }

      it "should exit immediately" do
        expect(subject).to receive(:signal_usage_error).and_call_original
        expect(subject).to receive(:show_short_help)
        expect(subject.run(args)).to eq(1)
      end
    end
  end

  describe "--config.test_and_exit" do
    subject { LogStash::Runner.new("") }
    let(:args) { ["-t", "-e", pipeline_string] }

    context "with a good configuration" do
      let(:pipeline_string) { "input { } filter { } output { }" }
      it "should exit successfully" do
        expect(logger).not_to receive(:fatal)
        expect(subject.run(args)).to eq(0)
      end
    end

    context "with a bad configuration" do
      let(:pipeline_string) { "rlwekjhrewlqrkjh" }
      it "should fail by returning a bad exit code" do
        expect(logger).to receive(:fatal)
        expect(subject.run(args)).to eq(1)
      end
    end

    context "with invalid field reference literal" do
      let(:pipeline_string) { "input { } output { if [[f[[[oo] == [bar] { } }" }
      it "should fail by returning a bad exit code" do
        expect(logger).to receive(:fatal)
        expect(subject.run(args)).to eq(1)
      end
    end
  end
  describe "pipeline settings" do
    let(:pipeline_string) { "input { stdin {} } output { stdout {} }" }
    let(:main_pipeline_settings) { { :pipeline_id => "main" } }
    let(:pipeline) { double("pipeline") }

    before(:each) do
      allow_any_instance_of(LogStash::Agent).to receive(:execute).and_return(true)
      task = Stud::Task.new { 1 }
      allow(pipeline).to receive(:run).and_return(task)
      allow(pipeline).to receive(:shutdown)
    end

    context "when :path.data is defined by the user" do
      let(:test_data_path) { "/tmp/ls-test-data" }
      let(:test_queue_path) { test_data_path + "/" + "queue" }
      let(:test_dlq_path) { test_data_path + "/" + "dead_letter_queue" }

      it "should set data paths" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.get("path.data")).to eq(test_data_path)
          expect(settings.get("path.queue")).to eq(test_queue_path)
          expect(settings.get("path.dead_letter_queue")).to eq(test_dlq_path)
        end

        args = ["--path.data", test_data_path, "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end

      context "and path.queue is manually set" do
        let(:queue_override_path) { "/tmp/queue-override_path" }

        it "should set data paths" do
          LogStash::SETTINGS.set("path.queue", queue_override_path)

          expect(LogStash::Agent).to receive(:new) do |settings|
            expect(settings.get("path.data")).to eq(test_data_path)
            expect(settings.get("path.queue")).to eq(queue_override_path)
          end

          args = ["--path.data", test_data_path, "-e", pipeline_string]
          subject.run("bin/logstash", args)
        end
      end

      context "and path.dead_letter_queue is manually set" do
        let(:queue_override_path) { "/tmp/queue-override_path" }

        it "should set data paths" do
          expect(LogStash::Agent).to receive(:new) do |settings|
            expect(settings.get("path.data")).to eq(test_data_path)
            expect(settings.get("path.dead_letter_queue")).to eq(queue_override_path)
          end

          LogStash::SETTINGS.set("path.dead_letter_queue", queue_override_path)

          args = ["--path.data", test_data_path, "-e", pipeline_string]
          subject.run("bin/logstash", args)
        end
      end
    end

    context ':api.http.host' do
      context "when undefined by the user" do
        let(:args) { ["-e", pipeline_string] }
        it "creates an Agent whose `api.http.host` uses the default value" do
          expect(LogStash::Agent).to receive(:new) do |settings|
            expect(settings.set?("api.http.host")).to be_falsey
            expect(settings.get("api.http.host")).to eq("127.0.0.1")
          end

          subject.run("bin/logstash", args)
        end
      end

      context "when defined by the user" do
        let(:args) { ["--api.http.host", "localhost", "-e", pipeline_string]}
        it "creates an Agent whose `api.http.host` uses provided value" do
          expect(LogStash::Agent).to receive(:new) do |settings|
            expect(settings.set?("api.http.host")).to be(true)
            expect(settings.get("api.http.host")).to eq("localhost")
          end

          subject.run("bin/logstash", args)
        end
      end

      context "using deprecated :http.host alias" do
        let(:deprecation_logger_stub) { double("DeprecationLogger(Settings)").as_null_object }
        before(:each) { allow(LogStash::Settings).to receive(:deprecation_logger).and_return(deprecation_logger_stub) }

        let(:runner_deprecation_logger_stub) { double("DeprecationLogger(Runner)").as_null_object }
        before(:each) { allow(runner).to receive(:deprecation_logger).and_return(runner_deprecation_logger_stub) }

        context "when deprecated :http.host is defined by the user" do
          let(:args) { ["--http.host", "localhost", "-e", pipeline_string]}
          it "creates an Agent whose `api.http.host` uses the provided value and provides helpful deprecation message" do
            expect(deprecation_logger_stub).to receive(:deprecated).with(a_string_including "`http.host` is a deprecated alias for `api.http.host`")
            expect(runner_deprecation_logger_stub).to receive(:deprecated).with(a_string_including 'The flag ["--http.host"] has been deprecated')
            expect(LogStash::Agent).to receive(:new) do |settings|
              expect(settings.set?("api.http.host")).to be(true)
              expect(settings.get("api.http.host")).to eq("localhost")
            end

            subject.run("bin/logstash", args)
          end
        end

        context "when :api.http.host and deprecated alias :http.host are both defined by the user" do
          it "errors helpfully" do
            args = ["--api.http.host", "api.local", "--http.host", "http.local", "-e", pipeline_string]
            expect do
              expect(subject.run("bin/logstash", args)).to_not eq(0)
            end.to output(a_string_including("Both `api.http.host` and its deprecated alias `http.host` have been set. Please only set `api.http.host`")).to_stderr
          end
        end
      end
    end

    context ":api.http.port" do
      context "when undefined by the user" do
        let(:args) { ["-e", pipeline_string] }
        it "creates an Agent whose `api.http.port` uses the default value" do
          expect(LogStash::Agent).to receive(:new) do |settings|
            expect(settings.set?("api.http.port")).to be_falsey
            expect(settings.get("api.http.port")).to eq(9600..9700)
          end

          subject.run("bin/logstash", args)
        end
      end

      context "when defined by the user" do
        let(:args) { ["--api.http.port", port_argument, "-e", pipeline_string] }
        context "as a single-value string" do
          let(:port_argument) { "10000" }
          it "creates an Agent whose `api.http.port` is an appropriate single-element range" do
            expect(LogStash::Agent).to receive(:new) do |settings|
              expect(settings.set?("api.http.port")).to be(true)
              expect(settings.get("api.http.port")).to eq(10000..10000)
            end

            subject.run("bin/logstash", args)
          end
        end
        context "as a range" do
          let(:port_argument) { "10000-20000" }
          it "creates an Agent whose `api.http.port` uses the appropriate inclusive-end range" do
            expect(LogStash::Agent).to receive(:new) do |settings|
              expect(settings.set?("api.http.port")).to be(true)
              expect(settings.get("api.http.port")).to eq(10000..20000)
            end

            subject.run("bin/logstash", args)
          end
        end
      end

      context "using deprecated :http.port alias" do
        let(:deprecation_logger_stub) { double("DeprecationLogger(Settings)").as_null_object }
        before(:each) { allow(LogStash::Settings).to receive(:deprecation_logger).and_return(deprecation_logger_stub) }

        let(:runner_deprecation_logger_stub) { double("DeprecationLogger(Runner)").as_null_object }
        before(:each) { allow(runner).to receive(:deprecation_logger).and_return(runner_deprecation_logger_stub) }

        context "when defined using deprecated :http.port alias" do
          let(:args) { ["--http.port", port_argument, "-e", pipeline_string] }

          context "as a single-value string" do
            let(:port_argument) { "10000" }
            it "creates an Agent whose `api.http.port` uses an appropriate single-element range and logs a helpful deprecation message" do
              expect(deprecation_logger_stub).to receive(:deprecated).with(a_string_including "`http.port` is a deprecated alias for `api.http.port`")
              expect(runner_deprecation_logger_stub).to receive(:deprecated).with(a_string_including 'The flag ["--http.port"] has been deprecated')

              expect(LogStash::Agent).to receive(:new) do |settings|
                expect(settings.set?("api.http.port")).to be(true)
                expect(settings.get("api.http.port")).to eq(10000..10000)
              end

              subject.run("bin/logstash", args)
            end
          end

          context "as a range" do
            let(:port_argument) { "10000-20000" }
            it "creates an Agent whose `api.http.port` uses the appropriate inclusive-end range and logs a helpful deprecation message" do
              expect(deprecation_logger_stub).to receive(:deprecated).with(a_string_including "`http.port` is a deprecated alias for `api.http.port`")
              expect(runner_deprecation_logger_stub).to receive(:deprecated).with(a_string_including 'The flag ["--http.port"] has been deprecated')

              expect(LogStash::Agent).to receive(:new) do |settings|
                expect(settings.set?("api.http.port")).to be(true)
                expect(settings.get("api.http.port")).to eq(10000..20000)
              end

              subject.run("bin/logstash", args)
            end
          end
        end

        context "when defined by both canonical name and deprecated :http.port alias" do
          let(:args) { ["--api.http.port", "9603", "--http.port", "9604", "-e", pipeline_string] }

          it "errors helpfully" do
            expect do
              expect(subject.run("bin/logstash", args)).to_not eq(0)
            end.to output(a_string_including("Both `api.http.port` and its deprecated alias `http.port` have been set. Please only set `api.http.port`")).to_stderr
          end
        end
      end
    end

    context "when :pipeline_workers is not defined by the user" do
      it "should not pass the value to the pipeline" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("pipeline.workers")).to be(false)
        end
        args = ["-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    context "when :pipeline_workers flag is passed without a value" do
      it "should raise an error" do
        args = ["-e", pipeline_string, "-w"]
        expect { subject.run("bin/logstash", args) }.to raise_error
      end
    end

    context "when :pipeline_workers is defined by the user" do
      it "should pass the value to the pipeline" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.set?("pipeline.workers")).to be(true)
          expect(settings.get("pipeline.workers")).to be(2)
        end

        args = ["-w", "2", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end

    describe "config.debug" do
      after(:each) do
        LogStash::SETTINGS.set("config.debug", false)
      end
      it "should set 'config.debug' to false by default" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.get("config.debug")).to eq(false)
        end
        args = ["--log.level", "debug", "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end

      it "should allow overriding config.debug" do
        expect(LogStash::Agent).to receive(:new) do |settings|
          expect(settings.get("config.debug")).to eq(true)
        end
        args = ["--log.level", "debug", "--config.debug",  "-e", pipeline_string]
        subject.run("bin/logstash", args)
      end
    end
  end

  describe "logstash modules" do
    before(:each) do
      test_modules_dir = File.expand_path(File.join(File.dirname(__FILE__), "..", "modules_test_files"))
      LogStash::Modules::Util.register_local_modules(test_modules_dir)
    end

    describe "--config.test_and_exit" do
      subject { LogStash::Runner.new("") }
      let(:args) { ["-t", "--modules", module_string] }

      context "with a good configuration" do
        let(:module_string) { "tester" }
        it "should exit successfully" do
          expect(logger).not_to receive(:fatal)
          expect(subject.run(args)).to eq(0)
        end
      end

      context "with a bad configuration" do
        let(:module_string) { "rlwekjhrewlqrkjh" }
        it "should fail by returning a bad exit code" do
          expect(logger).to receive(:fatal)
          expect(subject.run(args)).to eq(1)
        end
      end
    end

    describe "--modules" do
      let(:args) { ["--modules", module_string, "--setup"] }

      context "with an available module specified but no connection to elasticsearch" do
        let(:module_string) { "tester" }
        before do
          expect(logger).to receive(:fatal) do |msg, hash|
            expect(msg).to eq("An unexpected error occurred!")
            expect(hash).to be_a_config_loading_error_hash(
              /Failed to import module configurations to Elasticsearch and\/or Kibana. Module: tester has/)
          end
          expect(LogStash::Agent).to receive(:new) do |settings, source_loader|
            pipelines = LogStash::Config::ModulesCommon.pipeline_configs(settings)
            expect(pipelines).to eq([])
            agent
          end
        end
        it "should log fatally and return a bad exit code" do
          expect(subject.run("bin/logstash", args)).to eq(1)
        end
      end

      context "with an available module specified and a mocked connection to elasticsearch" do
        let(:module_string) { "tester" }
        let(:kbn_version) { "6.0.0" }
        let(:esclient) { double(:esclient) }
        let(:kbnclient) { double(:kbnclient) }
        let(:response) { double(:response) }
        before do
          allow(response).to receive(:status).and_return(404)
          allow(esclient).to receive(:head).and_return(response)
          allow(esclient).to receive(:can_connect?).and_return(true)
          allow(kbnclient).to receive(:version).and_return(kbn_version)
          allow(kbnclient).to receive(:version_parts).and_return(kbn_version.split('.'))
          allow(kbnclient).to receive(:can_connect?).and_return(true)
          allow(LogStash::ElasticsearchClient).to receive(:build).and_return(esclient)
          allow(LogStash::Modules::KibanaClient).to receive(:new).and_return(kbnclient)

          expect(esclient).to receive(:put).once do |path, content|
            LogStash::ElasticsearchClient::Response.new(201, "", {})
          end
          expect(kbnclient).to receive(:post).twice do |path, content|
            LogStash::Modules::KibanaClient::Response.new(201, "", {})
          end

          expect(LogStash::Agent).to receive(:new) do |settings, source_loader|
            pipelines = LogStash::Config::ModulesCommon.pipeline_configs(settings)
            expect(pipelines).not_to be_empty
            module_pipeline = pipelines.first
            expect(module_pipeline).to include("pipeline_id", "config_string")
            expect(module_pipeline["pipeline_id"]).to include('tester')
            expect(module_pipeline["config_string"]).to include('index => "tester-')
            agent
          end
          expect(logger).not_to receive(:fatal)
          expect(logger).not_to receive(:error)
        end
        it "should not terminate logstash" do
          expect(subject.run("bin/logstash", args)).to be_nil
        end
      end

      context "with an unavailable module specified" do
        let(:module_string) { "fancypants" }
        before do
          expect(logger).to receive(:fatal) do |msg, hash|
            expect(msg).to eq("An unexpected error occurred!")
            expect(hash).to be_a_config_loading_error_hash(
              /The modules specified are not available yet. Specified modules: \["fancypants"\] Available modules:/)
          end
          expect(LogStash::Agent).to receive(:new) do |settings, source_loader|
            pipelines = LogStash::Config::ModulesCommon.pipeline_configs(settings)
            expect(pipelines).to eq([])
            agent
          end
        end
        it "should log fatally and return a bad exit code" do
          expect(subject.run("bin/logstash", args)).to eq(1)
        end
      end
    end
  end

  describe 'jackson defaults' do
    subject { LogStash::Runner.new("") }
    let(:args) { ["-e", "input {} output {}"] }

    it 'should be set' do
      expect(LogStash::Util::Jackson).to receive(:set_jackson_defaults)
      subject.run(args)
    end
  end

  describe "--log.level" do
    before :each do
      allow_any_instance_of(subject).to receive(:show_version)
    end
    context "when not set" do
      it "should set log level to warn" do
        args = ["--version"]
        subject.run("bin/logstash", args)
        expect(logger.level).to eq(:info)
      end
    end
    context "when setting to debug" do
      it "should set log level to debug" do
        args = ["--log.level", "debug",  "--version"]
        subject.run("bin/logstash", args)
        expect(logger.level).to eq(:debug)
      end
    end
    context "when setting to verbose" do
      it "should set log level to info" do
        args = ["--log.level", "info",  "--version"]
        subject.run("bin/logstash", args)
        expect(logger.level).to eq(:info)
      end
    end
    context "when setting to quiet" do
      it "should set log level to error" do
        args = ["--log.level", "error",  "--version"]
        subject.run("bin/logstash", args)
        expect(logger.level).to eq(:error)
      end
    end

    context "deprecated flags" do
      let(:deprecation_logger_stub) { double("DeprecationLogger").as_null_object }
      before(:each) { allow(runner).to receive(:deprecation_logger).and_return(deprecation_logger_stub) }

      context "when using --quiet" do
        it "should warn about the deprecated flag" do
          expect(deprecation_logger_stub).to receive(:deprecated).with(/DEPRECATION WARNING/)
          args = ["--quiet", "--version"]
          subject.run("bin/logstash", args)
        end

        it "should still set the log level accordingly" do
          args = ["--quiet", "--version"]
          subject.run("bin/logstash", args)
          expect(logger.level).to eq(:error)
        end
      end
      context "when using --debug" do
        it "should warn about the deprecated flag" do
          expect(deprecation_logger_stub).to receive(:deprecated).with(/DEPRECATION WARNING/)
          args = ["--debug", "--version"]
          subject.run("bin/logstash", args)
        end

        it "should still set the log level accordingly" do
          args = ["--debug", "--version"]
          subject.run("bin/logstash", args)
          expect(logger.level).to eq(:debug)
        end
      end
      context "when using --verbose" do
        it "should warn about the deprecated flag" do
          expect(deprecation_logger_stub).to receive(:deprecated).with(/DEPRECATION WARNING/)
          args = ["--verbose", "--version"]
          subject.run("bin/logstash", args)
        end

        it "should still set the log level accordingly" do
          args = ["--verbose", "--version"]
          subject.run("bin/logstash", args)
          expect(logger.level).to eq(:info)
        end
      end
    end
  end

  describe "path.settings" do
    subject { LogStash::Runner.new("") }
    context "if does not exist" do
      let(:args) { ["--path.settings", "/tmp/a/a/a/a", "-e", "input { generator { count => 1000 }} output {}"] }

      it "should not terminate logstash" do
        # The runner should just pass the code from the agent execute
        allow(agent).to receive(:execute).and_return(0)
        expect(subject.run(args)).to eq(0)
      end

      context "but if --help is passed" do
        let(:args) { ["--path.settings", "/tmp/a/a/a/a", "--help"] }

        it "should show help" do
          expect { subject.run(args) }.to raise_error(Clamp::HelpWanted)
        end
      end
    end
  end

  describe "allow_superuser" do
    subject { LogStash::Runner.new("") }
    let(:args) { ["-e", "input {} output {}"] }
    let(:deprecation_logger_stub) { double("DeprecationLogger").as_null_object }
    before(:each) { allow(runner).to receive(:deprecation_logger).and_return(deprecation_logger_stub) }

    context "unintentionally running logstash as superuser" do
      before do
        expect(Process).to receive(:euid).and_return(0)
      end
      it "fails with bad exit" do
        LogStash::SETTINGS.set("allow_superuser", false)
        expect(logger).to receive(:fatal) do |msg, hash|
          expect(msg).to eq("An unexpected error occurred!")
          expect(hash[:error].to_s).to match("Logstash cannot be run as superuser.")
        end
        expect(subject.run(args)).to eq(1)
      end
    end

    context "intentionally running logstash as superuser " do
      before do
        expect(Process).to receive(:euid).and_return(0)
      end
      it "runs successfully with warning message" do
        LogStash::SETTINGS.set("allow_superuser", true)
        expect(logger).not_to receive(:fatal)
        expect(deprecation_logger_stub).to receive(:deprecated).with(/NOTICE: Running Logstash as superuser is not recommended and won't be allowed in the future. Set 'allow_superuser' to 'false' to avoid startup errors in future releases./)
        expect { subject.run(args) }.not_to raise_error
      end
    end

    context "running logstash as non-root " do
      before do
        expect(Process).to receive(:euid).and_return(100)
      end
      it "runs successfully without any messages" do
        LogStash::SETTINGS.set("allow_superuser", false)
        expect(logger).not_to receive(:fatal)
        expect(deprecation_logger_stub).not_to receive(:deprecated).with(/NOTICE: Running Logstash as superuser is not recommended and won't be allowed in the future. Set 'allow_superuser' to 'false' to avoid startup errors in future releases./)
        expect { subject.run(args) }.not_to raise_error
      end
    end
  end
end
