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

  let(:body) { LogStash::Json.load(last_response.body) }

  before(:each) do
    get "/"
  end

  it "should respond to root resource" do
    expect(last_response).to be_ok
  end

  it "contain a hostname" do
    expect(body).to include("hostname" => a_kind_of(String))
  end

  it "contain a version number" do
    expect(body).to include("version" => a_kind_of(String) )
  end

end
