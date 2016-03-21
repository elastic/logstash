# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/modules/stats"

describe LogStash::Api::Stats do

  include Rack::Test::Methods

  def app()
    described_class
  end

  it "respond to the jvm resource" do
    do_request { get "/jvm" }
    expect(last_response).to be_ok
  end

end
