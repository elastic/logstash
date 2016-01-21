# encoding: utf-8
ROOT = File.expand_path(File.join(File.dirname(__FILE__), ".."))
$LOAD_PATH.unshift File.join(ROOT, 'lib')
Dir.glob('lib/**').each{ |d| $LOAD_PATH.unshift(File.join(ROOT, d)) }

require "logstash/devutils/rspec/spec_helper"

require 'rack/test'
require 'rspec'
require "json"

ENV['RACK_ENV'] = 'test'

def read_fixture(name)
  path = File.join(File.dirname(__FILE__), "fixtures", name)
  HashWithIndifferentAccess.new(JSON.parse(File.read(path)))
end

class HashWithIndifferentAccess

  extend Forwardable
  def_delegators :@hash, :inject, :keys

  def initialize(hash)
    @hash = hash
  end

  def [](key)
    v = @hash[key.to_s]
    if (v.is_a?(Hash))
      return HashWithIndifferentAccess.new(v)
    end
    return OpenStruct.new(:value => v)
  end

  def marshal_dump
    h = {}
    @hash.each_pair do |k, v|
      if (!v.is_a?(Hash))
        h[k] = OpenStruct.new(:value => v)
      else
        h[k] = HashWithIndifferentAccess.new(v)
      end
    end
    HashWithIndifferentAccess.new(h)
  end
end
