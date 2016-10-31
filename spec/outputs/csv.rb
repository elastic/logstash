require "csv"
require "tempfile"
require "test_utils"
require "logstash/outputs/csv"

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

  describe "commas are quoted properly" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          add_field => ["foo","one,two", "baz", "quux"]
          count => 1
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
      insist {lines.count} == 1
      insist {lines[0]} == "\"one,two\",quux\n"
    end
  end

  describe "new lines are quoted properly" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          add_field => ["foo","one\ntwo", "baz", "quux"]
          count => 1
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
      lines = CSV.read(tmpfile.path)
      insist {lines.count} == 1
      insist {lines[0][0]} == "one\ntwo"
    end
  end
end





