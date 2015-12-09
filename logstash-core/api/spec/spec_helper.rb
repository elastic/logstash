# encoding: utf-8
ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift File.join(ROOT, 'lib')
Dir.glob('lib/**').each{ |d| $LOAD_PATH.unshift(File.join(ROOT, d)) }

require "logstash/devutils/rspec/spec_helper"

require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'
