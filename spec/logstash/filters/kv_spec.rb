require "spec_helper"
require "logstash/filters/kv"

describe LogStash::Filters::KV do

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
    end

  end

  describe "speed test", :performance => true do
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

    start = Time.now
    agent do
      duration = (Time.now - start)
      puts "filters/kv rate: #{"%02.0f/sec" % (count / duration)}, elapsed: #{duration}s"
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
        insist { subject["tags"] }.include?("hello")
      end
    end
    context "should not activate when failing" do
      config <<-CONFIG
        filter {
          kv { add_tag => "hello" }
        }
      CONFIG

      sample "this is not key value" do
        insist { subject["tags"] }.nil?
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
        insist { subject["whoa"] } == "fancypants"
      end
    end

    context "should not activate when failing" do
      config <<-CONFIG
        filter {
          kv { add_tag => "hello" }
        }
      CONFIG

      sample "this is not key value" do
        reject { subject["whoa"] } == "fancypants"
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
      insist {subject["kv"].count } == 5
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
    sample("data" => "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'") do
      insist { subject["hello"] } == "world"
      insist { subject["foo"] } == "bar"
      insist { subject["baz"] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
      insist { subject["singlequoted"] } == "hello world"
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
    sample("data" => "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'") do
      insist { subject["kv"]["hello"] } == "world"
      insist { subject["kv"]["foo"] } == "bar"
      insist { subject["kv"]["baz"] } == "fizz"
      insist { subject["kv"]["doublequoted"] } == "hello world"
      insist { subject["kv"]["singlequoted"] } == "hello world"
      insist { subject["kv"].count } == 5
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

  describe "test include_keys" do
    config <<-CONFIG
      filter {
        kv {
          include_keys => [ "foo", "singlequoted" ]
        }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["foo"] } == "bar"
      insist { subject["singlequoted"] } == "hello world"
    end
  end

  describe "test exclude_keys" do
    config <<-CONFIG
      filter {
        kv {
          exclude_keys => [ "foo", "singlequoted" ]
        }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["hello"] } == "world"
      insist { subject["baz"] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
    end
  end

  describe "test include_keys with prefix" do
    config <<-CONFIG
      filter {
        kv {
          include_keys => [ "foo", "singlequoted" ]
          prefix       => "__"
        }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["__foo"] } == "bar"
      insist { subject["__singlequoted"] } == "hello world"
    end
  end

  describe "test exclude_keys with prefix" do
    config <<-CONFIG
      filter {
        kv {
          exclude_keys => [ "foo", "singlequoted" ]
          prefix       => "__"
        }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["__hello"] } == "world"
      insist { subject["__baz"] } == "fizz"
      insist { subject["__doublequoted"] } == "hello world"
    end
  end
  
  describe "test include_keys with dynamic key" do
    config <<-CONFIG
      filter {
        kv {
          source => "data"
          include_keys => [ "%{key}"]
        }
      }
    CONFIG
    
    sample({"data" => "foo=bar baz=fizz", "key" => "foo"}) do
      insist { subject["foo"] } == "bar"
      insist { subject["baz"] } == nil
    end
  end
  
  describe "test exclude_keys with dynamic key" do
    config <<-CONFIG
      filter {
        kv {
          source => "data"
          exclude_keys => [ "%{key}"]
        }
      }
    CONFIG
    
    sample({"data" => "foo=bar baz=fizz", "key" => "foo"}) do
      insist { subject["foo"] } == nil
      insist { subject["baz"] } == "fizz"
    end
  end

  describe "test include_keys and exclude_keys" do
    config <<-CONFIG
      filter {
        kv {
          # This should exclude everything as a result of both settings.
          include_keys => [ "foo", "singlequoted" ]
          exclude_keys => [ "foo", "singlequoted" ]
        }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      %w(hello foo baz doublequoted singlequoted).each do |field|
        reject { subject }.include?(field)
      end
    end
  end

  describe "test default_keys" do
    config <<-CONFIG
      filter {
        kv {
          default_keys => [ "foo", "xxx",
                            "goo", "yyy" ]
        }
      }
    CONFIG

    sample "hello=world foo=bar baz=fizz doublequoted=\"hello world\" singlequoted='hello world'" do
      insist { subject["hello"] } == "world"
      insist { subject["foo"] } == "bar"
      insist { subject["goo"] } == "yyy"
      insist { subject["baz"] } == "fizz"
      insist { subject["doublequoted"] } == "hello world"
      insist { subject["singlequoted"] } == "hello world"
    end
  end

  describe "overwriting a string field (often the source)" do
    config <<-CONFIG
      filter {
        kv {
          source => "happy"
          target => "happy"
        }
      }
    CONFIG

    sample("happy" => "foo=bar baz=fizz") do
      insist { subject["[happy][foo]"] } == "bar"
      insist { subject["[happy][baz]"] } == "fizz"
    end

  end

end
