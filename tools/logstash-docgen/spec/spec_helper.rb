# encoding: utf-8
#
require "vcr"
require "webmock"
require_relative "support/helpers"

VCR.configure do |config|
  config.cassette_library_dir = ::File.join(::File.dirname(__FILE__), "fixtures", "vcr_cassettes")
  config.hook_into :webmock
end
