# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/system"

describe LogStash::Api::System do

  include Rack::Test::Methods

  def app()
    described_class
  end

  it "respond to the root resource" do
    get "/"
    expect(last_response).to be_ok
  end

   it "respond to the stats resource" do
    get "/stats"
    expect(last_response).to be_ok
  end

end
