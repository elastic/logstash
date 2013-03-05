require "test_utils"
require "logstash/filters/alter"

describe LogStash::Filters::Alter do
  extend LogStash::RSpec

  describe "condrewrite with static values" do
    config <<-CONFIG
    filter {
      alter {
        condrewrite => ["rewrite-me", "hello", "goodbye"]
      }
    }
    CONFIG

    sample "@fields" => {
      "rewrite-me"  => "hello"
    } do
      insist { subject["rewrite-me"] } == "goodbye"
    end

    sample "@fields" => {
      "rewrite-me"  => "greetings"
    } do
      insist { subject["rewrite-me"] } == "greetings"
    end
  end

  describe "condrewrite with dynamic values" do
    config <<-CONFIG
    filter {
      alter {
        condrewrite => ["rewrite-me", "%{test}", "%{rewrite-value}"]
      }
    }
    CONFIG

    sample "@fields" => {
      "rewrite-me"  => "hello",
      "test" => "hello",
      "rewrite-value" => "goodbye"
    } do
      insist { subject["rewrite-me"] } == "goodbye"
    end

    sample "@fields" => {
      "rewrite-me"  => "hello"
      #Missing test and rewrite fields
    } do
      insist { subject["rewrite-me"] } == "hello"
    end

    sample "@fields" => {
      "rewrite-me"  => "%{test}"
      #Missing test and rewrite fields
    } do
      insist { subject["rewrite-me"] } == "%{rewrite-value}"
    end

    sample "@fields" => {
      "rewrite-me"  => "hello",
      "test" => "hello"
      #Missing rewrite value
    } do
      insist { subject["rewrite-me"] } == "%{rewrite-value}"
    end

    sample "@fields" => {
      "rewrite-me"  => "greetings",
      "test" => "hello"
    } do
      insist { subject["rewrite-me"] } == "greetings"
    end
  end

  describe "condrewriteother" do
    config <<-CONFIG
    filter {
      alter {
        condrewriteother => ["test-me", "hello", "rewrite-me","goodbye"]
      }
    }
    CONFIG

    sample "@fields" => {
      "test-me"  => "hello"
    } do
      insist { subject["rewrite-me"] } == "goodbye"
    end

    sample "@fields" => {
      "test-me"  => "hello",
      "rewrite-me"  => "hello2"
    } do
      insist { subject["rewrite-me"] } == "goodbye"
    end

    sample "@fields" => {
      "test-me"  => "greetings"
    } do
      insist { subject["rewrite-me"] }.nil?
    end

    sample "@fields" => {
      "test-me"  => "greetings",
      "rewrite-me"  => "hello2"
    } do
      insist { subject["rewrite-me"] } == "hello2"
    end
  end

  describe "coalesce" do
    config <<-CONFIG
    filter {
      alter {
        coalesce => ["coalesce-me", "%{non-existing-field}", "mydefault"]
      }
    }
    CONFIG

    sample "@fields" => {
      "coalesce-me"  => "Hello"
    } do
      insist { subject["coalesce-me"] } == "mydefault" 
    end
  end
end
