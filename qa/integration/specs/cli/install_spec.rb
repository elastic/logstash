# encoding: utf-8
require_relative "../../framework/fixture"
require_relative "../../framework/settings"
require_relative "../../services/logstash_service"
require_relative "../../framework/helpers"
require "logstash/devutils/rspec/spec_helper"

def gem_in_lock_file?(pattern, lock_file)
  content =  File.read(lock_file)
  content.match(pattern)
end

describe "CLI > logstash-plugin install" do

  before(:all) do
    @fixture = Fixture.new(__FILE__)
    @logstash = @fixture.get_service("logstash")
    @logstash_plugin = @logstash.plugin_cli
    @pack_directory =  File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "logstash-dummy-pack"))
  end

  context "pack" do
    let(:pack) { "file://#{File.join(@pack_directory, "logstash-dummy-pack.zip")}" }

    # When you are on anything by linux we wont disable the internet with seccomp
    if RbConfig::CONFIG["host_os"] == "linux"
      context "without internet connection (linux seccomp wrapper)" do

        let(:offline_wrapper_path) { File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "fixtures", "offline_wrapper")) }

        before do
          Dir.chdir(offline_wrapper_path) do
            system("make clean")
            system("make")
          end
        end

        let(:offline_wrapper_cmd) { File.join(offline_wrapper_path, "offline") }

        it "successfully install the pack" do
          execute = @logstash_plugin.run_raw("#{offline_wrapper_cmd} bin/logstash-plugin install #{pack}")

          expect(execute.stderr_and_stdout).to match(/Install successful/)
          expect(execute.exit_code).to eq(0)

          installed = @logstash_plugin.list("logstash-output-secret")
          expect(installed.stderr_and_stdout).to match(/logstash-output-secret/)

          expect(gem_in_lock_file?(/gemoji/, @logstash.lock_file)).to be_truthy
        end
      end
    else
      context "with internet connection" do
        it "successfully install the pack" do
          execute = @logstash_plugin.install(pack)

          expect(execute.stderr_and_stdout).to match(/Install successful/)
          expect(execute.exit_code).to eq(0)

          installed = @logstash_plugin.list("logstash-output-secret")
          expect(installed.stderr_and_stdout).to match(/logstash-output-secret/)

          expect(gem_in_lock_file?(/gemoji/, @logstash.lock_file)).to be_truthy
        end
      end
    end
  end
end
