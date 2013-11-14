require "test_utils"
require "logstash/outputs/csv"
require "tempfile"

describe LogStash::Outputs::CSV do
  extend LogStash::RSpec

  describe "Write a single field to a csv file" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          add_field => ["foo","bar"]
          count => 1
        }
      }
      output {
        csv {
          path => "#{tmpfile.path}"
          fields => "foo"
        }
      }
    CONFIG

    agent do
      lines = File.readlines(tmpfile.path)
      insist {lines.count} == 1
      insist {lines[0]} == "bar\n"
    end
  end

  describe "write multiple fields and lines to a csv file" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          add_field => ["foo", "bar", "baz", "quux"]
          count => 2
        }
      }
      output {
        csv {
          path => "#{tmpfile.path}"
          fields => ["foo", "baz"]
        }
      }
    CONFIG

    agent do
      lines = File.readlines(tmpfile.path)
      insist {lines.count} == 2
      insist {lines[0]} == "bar,quux\n"
      insist {lines[1]} == "bar,quux\n"
    end
  end

  describe "missing event fields are empty in csv" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          add_field => ["foo","bar", "baz", "quux"]
          count => 1
        }
      }
      output {
        csv {
          path => "#{tmpfile.path}"
          fields => ["foo", "not_there", "baz"]
        }
      }
    CONFIG

    agent do
      lines = File.readlines(tmpfile.path)
      insist {lines.count} == 1
      insist {lines[0]} == "bar,,quux\n"
    end
  end
end





