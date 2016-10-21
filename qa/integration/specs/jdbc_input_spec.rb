require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require "logstash/devutils/rspec/spec_helper"

describe "Test JDBC Input" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    @driver_path = File.expand_path(File.join("..", "..", "services", "installed", "postgres-driver.jar"), __FILE__)
  }

  after(:all) {
    @fixture.teardown
  }
  
  #let(:config) { @fixture.config("root", { :driver_path => '/tmp/postgres-driver.jar' }) }
  let(:number_of_events) { 3 }
  let(:row1) { {"city"=>"San Francisco", "join_date"=>"2014-02-10T08:00:00.000Z", "name"=>"John", "id"=>1, "title"=>"Engineer", "age"=>100} }
  let(:row2) { {"city"=>"San Jose", "join_date"=>"2015-02-10T08:00:00.000Z", "name"=>"Jane", "id"=>2, "title"=>"CTO", "age"=>101} }
  let(:row3) { {"city"=>"Mobile", "join_date"=>"2016-02-10T08:00:00.000Z", "name"=>"Jack", "id"=>3, "title"=>"Engineer", "age"=>102} }
  
  def remove_meta_fields(line)
    line.delete("@version")
    line.delete("@timestamp")
    line
  end  

  it "can retrieve events from table" do
    puts @driver_path
    logstash_service = @fixture.get_service("logstash")
    logstash_service.start_background(@fixture.config)
    
    try(20) do
      expect(@fixture.output_exists?).to be true
    end
    
    lines = []
    try do
      lines = File.readlines(@fixture.actual_output)
      expect(lines.size).to eq(number_of_events)
    end
    
    expect(remove_meta_fields(JSON.load(lines[0]))).to eq(row1)
    expect(remove_meta_fields(JSON.load(lines[1]))).to eq(row2)
    expect(remove_meta_fields(JSON.load(lines[2]))).to eq(row3)
  end
end
