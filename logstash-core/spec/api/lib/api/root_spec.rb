# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/root"
require "logstash/json"

describe LogStash::Api::Root do

  include Rack::Test::Methods

  def app()
    described_class
  end

  it "should respond to root resource" do
    get "/"
    expect(last_response).to be_ok
  end

end
