require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require "socket"
require "yaml"
require 'rspec/wait'

describe "Test Logstash service when multiple pipelines are used" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    @fixture.teardown
  }

  let(:temporary_out_file_1) { Stud::Temporary.pathname }
  let(:temporary_out_file_2) { Stud::Temporary.pathname }

  let(:pipelines) {[
    {
      "pipeline.id" => "test",
      "pipeline.workers" => 1,
      "pipeline.batch.size" => 1,
      "config.string" => "input { generator { count => 1 } } output { file { path => \"#{temporary_out_file_1}\" } }"
    },
    {
      "pipeline.id" => "test2",
      "pipeline.workers" => 1,
      "pipeline.batch.size" => 1,
      "config.string" => "input { generator { count => 1 } } output { file { path => \"#{temporary_out_file_2}\" } }"
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
    wait(60).for do
      logstash_service.exited?
    end.to be true
    expect(logstash_service.exit_code).to eq(0)
    expect(File.exist?(temporary_out_file_1)).to be(true)
    expect(IO.readlines(temporary_out_file_1).size).to eq(1)
    expect(File.exist?(temporary_out_file_2)).to be(true)
    expect(IO.readlines(temporary_out_file_2).size).to eq(1)
  end
end
