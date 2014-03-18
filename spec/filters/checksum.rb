# encoding: utf-8

require "test_utils"
require "logstash/filters/checksum"
require 'openssl'

describe LogStash::Filters::Checksum do
  extend LogStash::RSpec

  LogStash::Filters::Checksum::ALGORITHMS.each do |alg|
    describe "#{alg} checksum with single field" do
      config <<-CONFIG
        filter {
          checksum {
            algorithm => "#{alg}"
            keys => ["test"]
          }
        }
        CONFIG

      sample "test" => "foo bar" do
        insist { !subject["logstash_checksum"].nil? }
        insist { subject["logstash_checksum"] } == OpenSSL::Digest.hexdigest(alg, "|test|foo bar|")
      end
    end

    describe "#{alg} checksum with multiple keys" do
      config <<-CONFIG
        filter {
          checksum {
            algorithm => "#{alg}"
            keys => ["test1", "test2"]
          }
        }
        CONFIG

      sample "test1" => "foo", "test2" => "bar" do
        insist { !subject["logstash_checksum"].nil? }
        insist { subject["logstash_checksum"] } == OpenSSL::Digest.hexdigest(alg, "|test1|foo|test2|bar|")
      end
    end
  end
end
