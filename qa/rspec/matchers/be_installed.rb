# encoding: utf-8
require 'rspec/expectations'
require_relative '../helpers'

RSpec::Matchers.define :be_installed do
  match do |subject|
    subject.installed?(subject.hosts, subject.name)
  end
end

RSpec::Matchers.define :be_removed do
  match do |subject|
    subject.removed?(subject.hosts, subject.name)
  end
end
