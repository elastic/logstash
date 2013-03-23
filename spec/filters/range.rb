require "test_utils"
require "logstash/filters/range"

describe LogStash::Filters::Range do
  extend LogStash::RSpec

  describe "range match integer field on tag action" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "duration", 10, 100, "tag:cool",
                      "duration", 1, 1, "tag:boring" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "duration" => 50
    } do
      insist { subject["@tags"] }.include?("cool")
      reject { subject["@tags"] }.include?("boring")
    end
  end

  describe "range match float field on tag action" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "duration", 0, 100, "tag:cool",
                      "duration", 0, 1, "tag:boring" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "duration" => 50.0
    } do
      insist { subject["@tags"] }.include?("cool")
      reject { subject["@tags"] }.include?("boring")
    end
  end

  describe "range match string field on tag action" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "length", 0, 10, "tag:cool",
                      "length", 0, 1, "tag:boring" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "length" => "123456789"
    } do
      insist { subject["@tags"] }.include?("cool")
      reject { subject["@tags"] }.include?("boring")
    end
  end

  describe "range match with negation" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "length", 0, 10, "tag:cool",
                      "length", 0, 1, "tag:boring" ]
          negate => true
        }
      }
    CONFIG

    sample "@fields" => {
      "length" => "123456789"
    } do
      reject { subject["@tags"] }.include?("cool")
      insist { subject["@tags"] }.include?("boring")
    end
  end

  describe "range match on drop action" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "length", 0, 10, "drop" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "length" => "123456789"
    } do
      insist { subject }.nil?
    end
  end

  describe "range match on field action with string value" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "duration", 10, 100, "field:cool:foo",
                      "duration", 1, 1, "field:boring:foo" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "duration" => 50
    } do
      insist { subject["@fields"] }.include?("cool")
      insist { subject["@fields"]["cool"] } == "foo"
      reject { subject["@fields"] }.include?("boring")
    end
  end

  describe "range match on field action with integer value" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "duration", 10, 100, "field:cool:666",
                      "duration", 1, 1, "field:boring:666" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "duration" => 50
    } do
      insist { subject["@fields"] }.include?("cool")
      insist { subject["@fields"]["cool"] } == 666
      reject { subject["@fields"] }.include?("boring")
    end
  end

  describe "range match on field action with float value" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "duration", 10, 100, "field:cool:3.14",
                      "duration", 1, 1, "field:boring:3.14" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "duration" => 50
    } do
      insist { subject["@fields"] }.include?("cool")
      insist { subject["@fields"]["cool"] } == 3.14
      reject { subject["@fields"] }.include?("boring")
    end
  end

  describe "range match on tag action with dynamic string value" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "duration", 10, 100, "tag:cool_%{dynamic}_dynamic",
                      "duration", 1, 1, "tag:boring_%{dynamic}_dynamic" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "duration" => 50,
      "dynamic" => "and"
    } do
      insist { subject["@tags"] }.include?("cool_and_dynamic")
      reject { subject["@tags"] }.include?("boring_and_dynamic")
    end
  end

  describe "range match on field action with dynamic string field and value" do
    config <<-CONFIG
      filter {
        range {
          ranges => [ "duration", 10, 100, "field:cool_%{dynamic}_dynamic:foo_%{dynamic}_bar",
                      "duration", 1, 1, "field:boring_%{dynamic}_dynamic:foo_%{dynamic}_bar" ]
        }
      }
    CONFIG

    sample "@fields" => {
      "duration" => 50,
      "dynamic" => "and"
    } do
      insist { subject["@fields"] }.include?("cool_and_dynamic")
      insist { subject["@fields"]["cool_and_dynamic"] } == "foo_and_bar"
      reject { subject["@fields"] }.include?("boring_and_dynamic")
    end
  end
end