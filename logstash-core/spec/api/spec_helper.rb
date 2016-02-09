# encoding: utf-8
ROOT = File.expand_path(File.join(File.dirname(__FILE__), "..", "..", "lib", "logstash", "api"))
$LOAD_PATH.unshift File.join(ROOT, 'lib')
Dir.glob(File.join(ROOT, "lib" "**")).each{ |d| $LOAD_PATH.unshift(d) }

require "logstash/devutils/rspec/spec_helper"

require 'rack/test'
require 'rspec'
require "json"

ENV['RACK_ENV'] = 'test'

Rack::Builder.parse_file(File.join(ROOT, 'init.ru'))

def read_fixture(name)
  path = File.join(File.dirname(__FILE__), "fixtures", name)
  File.read(path)
end
