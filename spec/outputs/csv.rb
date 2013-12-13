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

  describe "fields that are are objects are written as JSON" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          message => '{"foo":{"one":"two"},"baz": "quux"}'
          count => 1
        }
      }
      filter {
        json { source => "message"}
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
      insist {lines[0][0]} == '{"one":"two"}'
    end
  end

  describe "can address nested field using field reference syntax" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          message => '{"foo":{"one":"two"},"baz": "quux"}'
          count => 1
        }
      }
      filter {
        json { source => "message"}
      }
      output {
        csv {
          path => "#{tmpfile.path}"
          fields => ["[foo][one]", "baz"]
        }
      }
    CONFIG

    agent do
      lines = CSV.read(tmpfile.path)
      insist {lines.count} == 1
      insist {lines[0][0]} == "two"
      insist {lines[0][1]} == "quux"
    end
  end

  describe "missing nested field is blank" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          message => '{"foo":{"one":"two"},"baz": "quux"}'
          count => 1
        }
      }
      filter {
        json { source => "message"}
      }
      output {
        csv {
          path => "#{tmpfile.path}"
          fields => ["[foo][missing]", "baz"]
        }
      }
    CONFIG

    agent do
      lines = File.readlines(tmpfile.path)
      insist {lines.count} == 1
      insist {lines[0]} == ",quux\n"
    end
  end

  describe "can choose field seperator" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          message => '{"foo":"one","bar": "two"}'
          count => 1
        }
      }
      filter {
        json { source => "message"}
      }
      output {
        csv {
          path => "#{tmpfile.path}"
          fields => ["foo", "bar"]
          csv_options => {"col_sep" => "|"}
        }
      }
    CONFIG

    agent do
      lines = File.readlines(tmpfile.path)
      insist {lines.count} == 1
      insist {lines[0]} == "one|two\n"
    end
  end
  describe "can choose line seperator" do
    tmpfile = Tempfile.new('logstash-spec-output-csv')
    config <<-CONFIG
      input {
        generator {
          message => '{"foo":"one","bar": "two"}'
          count => 2
        }
      }
      filter {
        json { source => "message"}
      }
      output {
        csv {
          path => "#{tmpfile.path}"
          fields => ["foo", "bar"]
          csv_options => {"col_sep" => "|" "row_sep" => "\t"}
        }
      }
    CONFIG

    agent do
      lines = File.readlines(tmpfile.path)
      insist {lines.count} == 1
      insist {lines[0]} == "one|two\tone|two\t"
    end
  end
end
