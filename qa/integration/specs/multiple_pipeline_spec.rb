require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "logstash/devutils/rspec/spec_helper"
require "socket"
require "yaml"

describe "Test Logstash service when multiple pipelines are used" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  let(:pipelines) {[
    {
      "pipeline.id" => "test",
      "pipeline.workers" => 1,
      "pipeline.batch.size" => 1,
      "config.string" => "input { } output { }"
    },
    {
      "pipeline.id" => "test2",
      "pipeline.workers" => 1,
      "pipeline.batch.size" => 1,
      "config.string" => "input { } output { }"
    }
  ]}

  let!(:settings_dir) { Stud::Temporary.directory }
  let!(:pipelines_yaml) { pipelines.to_yaml }
  let!(:pipelines_yaml_file) { ::File.join(settings_dir, "pipelines.yml") }

  let(:retry_attempts) { 30 }

  before(:each) do
    IO.write(pipelines_yaml_file, pipelines_yaml)
  end

  it "executes the multiple pipelines" do
    logstash_service = @fixture.get_service("logstash")
    logstash_service.spawn_logstash("--path.settings", settings_dir, "--log.level=debug")
    try(retry_attempts) do
      expect(logstash_service.exited?).to be(true)
    end
    expect(logstash_service.exit_code).to eq(0)
  end
end
