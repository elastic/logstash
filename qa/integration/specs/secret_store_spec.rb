require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"

### Logstash Keystore notes #############
# The logstash.keystore password is `keystore_pa9454w3rd` and contains the following entries:
# input.count = 10
# output.path = mypath
# pipeline.id = mypipeline
# tag1 = mytag1
# tag2 = mytag2
# tag3 = mytag3
####################################
describe "Test that Logstash" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  before(:each) {
    @logstash = @fixture.get_service("logstash")
    IO.write(File.join(settings_dir, "logstash.yml"), YAML.dump(settings))
    FileUtils.cp(File.expand_path("../../logstash.keystore", __FILE__), settings_dir)
  }

  after(:all) {
    @fixture.teardown
  }

  after(:each) {
    @logstash.teardown
  }

  let(:num_retries) {50}
  let(:test_path) {Stud::Temporary.directory}
  let(:test_env) {Hash.new}
  let(:settings_dir) {Stud::Temporary.directory}
  let(:settings) {{"pipeline.id" => "${pipeline.id}"}}

  it "expands secret store variables from config" do
    test_env["TEST_ENV_PATH"] = test_path
    test_env["LOGSTASH_KEYSTORE_PASS"] = "keystore_pa9454w3rd"
    @logstash.env_variables = test_env
    @logstash.start_background_with_config_settings(config_to_temp_file(@fixture.config), settings_dir)
    Stud.try(num_retries.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      # 10 generated outputs, mypath, and the tags all come from the secret store
      expect(IO.read(File.join(File.join(test_path, "mypath"), "logstash_secretstore_test.output")).gsub("\n", "")).to eq("Hello world! mytag1,mytag2.mytag3" * 10)
    end
  end

  it "expands secret store variables from settings" do
    test_env["LOGSTASH_KEYSTORE_PASS"] = "keystore_pa9454w3rd"
    @logstash.env_variables = test_env
    @logstash.spawn_logstash("-e", "input {heartbeat {}} output { }", "--path.settings", settings_dir)
    Stud.try(num_retries.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      result = @logstash.monitoring_api.node_stats rescue nil
      expect(result).not_to be_nil
      # mypipeline comes the secret store
      mypipeline = result.fetch('pipelines').fetch('mypipeline')
      expect(mypipeline).not_to be_nil
    end
  end

  context "won't start" do
    it "with the wrong password when variables are in settings" do
      test_env["LOGSTASH_KEYSTORE_PASS"] = "WRONG_PASSWRD"
      @logstash.env_variables = test_env
      @logstash.spawn_logstash("-e", "input {generator { count => 1 }} output { }", "--path.settings", settings_dir)
      try(num_retries) do
        expect(@logstash.exited?).to be(true)
      end
      expect(@logstash.exit_code).to be(1)
    end
  end

  context "will start" do
    let(:settings) {{"pipeline.id" => "main"}}
    it "with the wrong password and variables are NOT in settings" do
      test_env["LOGSTASH_KEYSTORE_PASS"] = "WRONG_PASSWRD"
      @logstash.env_variables = test_env
      @logstash.spawn_logstash("-e", "input {generator { count => 1 }} output { }", "--path.settings", settings_dir)
      try(num_retries) do
        expect(@logstash.exited?).to be(true)
      end
      expect(@logstash.exit_code).to be(0)
    end
  end

  context "won't start " do
    let(:settings) {{"pipeline.id" => "${missing}"}}
    it "with correct password, but invalid variable " do
      test_env["LOGSTASH_KEYSTORE_PASS"] = "keystore_pa9454w3rd"
      @logstash.env_variables = test_env
      @logstash.spawn_logstash("-e", "input {stdin {}} output { }", "--path.settings", settings_dir)
      try(num_retries) do
        expect(@logstash.exited?).to be(true)
      end
      expect(@logstash.exit_code).to be(1)
    end
  end
end
