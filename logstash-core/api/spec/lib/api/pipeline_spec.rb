# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/pipeline"

describe LogStash::Api::Pipeline do

  include Rack::Test::Methods

  def app()
    described_class
  end

  it "respond to the info resource" do
    get "/info"
    expect(last_response).to be_ok
  end

  it "respond to the stats resource" do
    get "/stats"
    expect(last_response).to be_ok
  end

  it "respond to the stats resource" do
    get "/plugins"
    expect(last_response).to be_ok
  end

end
