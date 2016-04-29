# encoding: utf-8
require 'rspec/expectations'
require_relative '../helpers'

RSpec::Matchers.define :be_running do

  match do |subject|
    subject.client.running?(subject.hosts, subject.name)
  end
end
