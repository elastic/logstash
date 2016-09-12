# encoding: utf-8
require_relative "../spec_helper"
require "logstash/api/errors"

describe LogStash::Api::ApiError do
  subject { described_class.new }

  it "#status_code returns 500" do
    expect(subject.status_code).to eq(500)
  end

  it "#to_hash return the message of the exception" do
    expect(subject.to_hash).to include(:message => "Api Error")
  end
end

describe LogStash::Api::NotFoundError do
  subject { described_class.new }

  it "#status_code returns 404" do
    expect(subject.status_code).to eq(404)
  end

  it "#to_hash return the message of the exception" do
    expect(subject.to_hash).to include(:message => "Not Found")
  end
end
