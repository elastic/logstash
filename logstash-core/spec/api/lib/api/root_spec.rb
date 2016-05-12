# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "logstash/api/modules/root"
require "logstash/json"

describe LogStash::Api::Modules::Root do

  include Rack::Test::Methods

  def app()
    described_class
  end

  it "should respond to root resource" do
    do_request { get "/" }
    expect(last_response).to be_ok
  end

end
