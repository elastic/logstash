# encoding: utf-8
require 'rspec/expectations'
require_relative '../helpers'

RSpec::Matchers.define :be_installed do

  match do |actual|
    select_client.installed?([@host], actual)
  end

  chain :on do |host|
    @host = host
  end
end

RSpec::Matchers.define :be_removed do

  match do |actual|
    select_client.removed?([@host], actual)
  end

  chain :on do |host|
    @host = host
  end
end
