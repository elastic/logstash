require "test_utils"
require "logstash/filters/kv"

describe LogStash::Filters::KV do
  extend LogStash::RSpec

  describe "defaults" do
    # The logstash config goes here.
    # At this time, only filters are supported.
    config <<-CONFIG
      filter {
        kv { }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["hello"] } == "world"
      insist { subject["foo"] } == "bar"
      insist { subject["baz"] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
      insist { subject["singlequoted"] } == "hello world"
      insist {subject['@fields'].count } == 5
    end

  end

   describe "LOGSTASH-624: allow escaped space in key or value " do
    config <<-CONFIG
      filter {
        kv { value_split => ':' }
      }
    CONFIG

    sample 'IKE:=Quick\ Mode\ completion IKE\ IDs:=subnet:\ x.x.x.x\ (mask=\ 255.255.255.254)\ and\ host:\ y.y.y.y' do
      insist { subject["IKE"] } == '=Quick\ Mode\ completion'
      insist { subject['IKE\ IDs'] } == '=subnet:\ x.x.x.x\ (mask=\ 255.255.255.254)\ and\ host:\ y.y.y.y'
    end
  end

  describe "test value_split" do
    config <<-CONFIG
      filter {
        kv { value_split => ':' }
      }
    CONFIG

    sample "hello:=world foo:bar baz=:fizz doublequoted:\"hello world\" singlequoted:'hello world'" do
      insist { subject["hello"] } == "=world"
      insist { subject["foo"] } == "bar"
      insist { subject["baz="] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
      insist { subject["singlequoted"] } == "hello world"
      insist {subject['@fields'].count } == 5
    end

  end

  describe "test field_split" do
    config <<-CONFIG
      filter {
        kv { field_split => '?&' }
      }
    CONFIG

    sample "?hello=world&foo=bar&baz=fizz&doublequoted=\"hello world\"&singlequoted='hello world'&ignoreme&foo12=bar12" do
      insist { subject["hello"] } == "world"
      insist { subject["foo"] } == "bar"
      insist { subject["baz"] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
      insist { subject["singlequoted"] } == "hello world"
      insist { subject["foo12"] } == "bar12"
      insist {subject['@fields'].count } == 6
    end

  end

  describe  "delimited fields should override space default (reported by LOGSTASH-733)" do
    config <<-CONFIG
      filter {
        kv { field_split => "|" }
      }
    CONFIG

    sample "field1=test|field2=another test|field3=test3" do
      insist { subject["field1"] } == "test"
      insist { subject["field2"] } == "another test"
      insist { subject["field3"] } == "test3"
    end
  end

  describe "test prefix" do
    config <<-CONFIG
      filter {
        kv { prefix => '__' }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["__hello"] } == "world"
      insist { subject["__foo"] } == "bar"
      insist { subject["__baz"] } == "fizz"
      insist { subject["__doublequoted"] } == "hello world"
      insist { subject["__singlequoted"] } == "hello world"
      insist {subject['@fields'].count } == 5
    end

  end

  describe "test container (deprecated test)" do
    config <<-CONFIG
      filter {
        kv { container => 'kv' }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["kv"]["hello"] } == "world"
      insist { subject["kv"]["foo"] } == "bar"
      insist { subject["kv"]["baz"] } == "fizz"
      insist { subject["kv"]["doublequoted"] } == "hello world"
      insist { subject["kv"]["singlequoted"] } == "hello world"
      insist {subject['@fields']["kv"].count } == 5
    end

  end

  describe "test empty container (deprecated test)" do
    config <<-CONFIG
      filter {
        kv { container => 'kv' }
      }
    CONFIG

    sample "hello:world:foo:bar:baz:fizz" do
      insist { subject["kv"] } == nil
      insist {subject['@fields'].count } == 0
    end

  end

  describe "speed test" do
    count = 10000 + rand(3000)
    config <<-CONFIG
      input {
        generator {
          count => #{count}
          type => foo
          message => "hello=world bar='baz fizzle'"
        }
      }

      filter {
        kv { }
      }

      output  {
        null { }
      }
    CONFIG

    agent do
      p :duration => @duration, :rate => count/@duration
    end
  end

  describe "add_tag" do
    context "should activate when successful" do
      config <<-CONFIG
        filter {
          kv { add_tag => "hello" }
        }
      CONFIG

      sample "hello=world" do
        insist { subject["hello"] } == "world"
        insist { subject["@tags"] }.include?("hello")
      end
    end
    context "should not activate when failing" do
      config <<-CONFIG
        filter {
          kv { add_tag => "hello" }
        }
      CONFIG

      sample "this is not key value" do
        reject { subject["@tags"] }.include?("hello")
      end
    end
  end

  describe "add_field" do
    context "should activate when successful" do
      config <<-CONFIG
        filter {
          kv { add_field => [ "whoa", "fancypants" ] }
        }
      CONFIG

      sample "hello=world" do
        insist { subject["hello"] } == "world"
        insist { subject["whoa"] } == [ "fancypants" ]
      end
    end

    context "should not activate when failing" do
      config <<-CONFIG
        filter {
          kv { add_tag => "hello" }
        }
      CONFIG

      sample "this is not key value" do
        reject { subject["whoa"] } == [ "fancypants" ]
      end
    end
  end

  #New tests
  describe "test target" do
    config <<-CONFIG
      filter {
        kv { target => 'kv' }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["kv"]["hello"] } == "world"
      insist { subject["kv"]["foo"] } == "bar"
      insist { subject["kv"]["baz"] } == "fizz"
      insist { subject["kv"]["doublequoted"] } == "hello world"
      insist { subject["kv"]["singlequoted"] } == "hello world"
      insist {subject['@fields']["kv"].count } == 5
    end

  end

  describe "test empty target" do
    config <<-CONFIG
      filter {
        kv { target => 'kv' }
      }
    CONFIG

    sample "hello:world:foo:bar:baz:fizz" do
      insist { subject["kv"] } == nil
      insist {subject['@fields'].count } == 0
    end
  end


  describe "test data from specific sub source" do
    config <<-CONFIG
      filter {
        kv {
          source => "data"
        }
      }
    CONFIG
    sample({"@fields" => {"data" => "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'"}}) do
      insist { subject["hello"] } == "world"
      insist { subject["foo"] } == "bar"
      insist { subject["baz"] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
      insist { subject["singlequoted"] } == "hello world"
      insist { subject['@fields'].count } == 6
    end
  end

  describe "test data from specific top source" do
    config <<-CONFIG
      filter {
        kv {
          source => "@data"
        }
      }
    CONFIG
    sample({"@data" => "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'"}) do
      insist { subject["hello"] } == "world"
      insist { subject["foo"] } == "bar"
      insist { subject["baz"] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
      insist { subject["singlequoted"] } == "hello world"
      insist { subject['@fields'].count } == 5
    end
  end


  describe "test data from specific sub source and target" do
    config <<-CONFIG
      filter {
        kv {
          source => "data"
          target => "kv"
        }
      }
    CONFIG
    sample({"@fields" => {"data" => "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'"}}) do
      insist { subject["kv"]["hello"] } == "world"
      insist { subject["kv"]["foo"] } == "bar"
      insist { subject["kv"]["baz"] } == "fizz"
      insist { subject["kv"]["doublequoted"] } == "hello world"
      insist { subject["kv"]["singlequoted"] } == "hello world"
      insist { subject['@fields']["kv"].count } == 5
    end
  end

  describe "test data from nil sub source, should not issue a warning" do
    config <<-CONFIG
      filter {
        kv {
          source => "non-exisiting-field"
          target => "kv"
        }
      }
    CONFIG
    sample "" do
      insist { subject["non-exisiting-field"] } == nil
      insist { subject["kv"] } == nil
    end
  end

end
