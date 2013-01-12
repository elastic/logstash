require "test_utils"
require "logstash/filters/xml"

describe LogStash::Filters::Xml do
  extend LogStash::RSpec

  describe "parse standard xml (Deprecated checks)" do
    config <<-CONFIG
    filter {
      xml {
        raw => "data"
      }
    }
    CONFIG

    sample({"@fields" => {"raw" => '<foo key="value"/>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["data"]} == {"key" => "value"}
    end

    #From parse xml with array as a value
    sample({"@fields" => {"raw" => '<foo><key>value1</key><key>value2</key></foo>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["data"]} == {"key" => ["value1", "value2"]}
    end

    #From parse xml with hash as a value
    sample({"@fields" => {"raw" => '<foo><key1><key2>value</key2></key1></foo>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["data"]} == {"key1" => [{"key2" => ["value"]}]}
    end

    #From bad xml
    sample({"@fields" => {"raw" => '<foo /'}}) do
      insist { subject.tags}.include?("_xmlparsefailure")
    end
  end

  describe "parse standard xml but do not store (Deprecated checks)" do
    config <<-CONFIG
    filter {
      xml {
        raw => "data"
        store_xml => false
      }
    }
    CONFIG

    sample({"@fields" => {"raw" => '<foo key="value"/>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["data"]} == nil
    end
  end

  describe "parse xml and store values with xpath (Deprecated checks)" do
    config <<-CONFIG
    filter {
      xml {
        raw => "data"
        xpath => [ "/foo/key/text()", "xpath_field" ]
      }
    }
    CONFIG

    # Single value
    sample({"@fields" => {"raw" => '<foo><key>value</key></foo>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["xpath_field"]} == ["value"]
    end

    #Multiple values
    sample({"@fields" => {"raw" => '<foo><key>value1</key><key>value2</key></foo>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["xpath_field"]} == ["value1","value2"]
    end
  end

  ## New tests

  describe "parse standard xml" do
    config <<-CONFIG
    filter {
      xml {
        source => "xmldata"
        target => "data"
      }
    }
    CONFIG

    sample({"@fields" => {"xmldata" => '<foo key="value"/>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["data"]} == {"key" => "value"}
    end

    #From parse xml with array as a value
    sample({"@fields" => {"xmldata" => '<foo><key>value1</key><key>value2</key></foo>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["data"]} == {"key" => ["value1", "value2"]}
    end

    #From parse xml with hash as a value
    sample({"@fields" => {"xmldata" => '<foo><key1><key2>value</key2></key1></foo>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["data"]} == {"key1" => [{"key2" => ["value"]}]}
    end

    #From bad xml
    sample({"@fields" => {"xmldata" => '<foo /'}}) do
      insist { subject.tags}.include?("_xmlparsefailure")
    end
  end

  describe "parse standard xml but do not store" do
    config <<-CONFIG
    filter {
      xml {
        source => "xmldata"
        target => "data"
        store_xml => false
      }
    }
    CONFIG

    sample({"@fields" => {"xmldata" => '<foo key="value"/>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["data"]} == nil
    end
  end

  describe "parse xml and store values with xpath" do
    config <<-CONFIG
    filter {
      xml {
        source => "xmldata"
        target => "data"
        xpath => [ "/foo/key/text()", "xpath_field" ]
      }
    }
    CONFIG

    # Single value
    sample({"@fields" => {"xmldata" => '<foo><key>value</key></foo>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["xpath_field"]} == ["value"]
    end

    #Multiple values
    sample({"@fields" => {"xmldata" => '<foo><key>value1</key><key>value2</key></foo>'}}) do
      reject { subject.tags}.include?("_xmlparsefailure")
      insist { subject["xpath_field"]} == ["value1","value2"]
    end
  end

end
