# encoding: utf-8
require 'rspec/expectations'
require_relative '../helpers'

RSpec::Matchers.define :be_running do

  match do |actual|
    select_client.running?([@host], actual)
  end

  chain :on do |host|
    @host = host
  end
end
