require "test_utils"
require "logstash/filters/dns"

describe LogStash::Filters::DNS do
  extend LogStash::RSpec

  describe "dns reverse lookup, replace (on event.source)" do
    config <<-CONFIG
      filter {
        dns {
          reverse => "@source"
          action => "replace"
        }
      }
    CONFIG

    sample({"@source" => "199.192.228.250"}) do
      insist { subject.source } == "carrera.databits.net"
    end
  end

  describe "dns reverse lookup, replace (on a field)" do
    config <<-CONFIG
      filter {
        dns {
          reverse => "foo"
          action => "replace"
        }
      }
    CONFIG

    sample({"@fields" => { "foo" => "199.192.228.250"}}) do
      insist { subject["foo"] } == "carrera.databits.net"
    end
  end

  describe "dns reverse lookup, append" do
    config <<-CONFIG
      filter {
        dns {
          reverse => "foo"
          action => "append"
        }
      }
    CONFIG

    sample({"@fields" => { "foo" => "199.192.228.250"}}) do
      insist { subject["foo"][0] } == "199.192.228.250"
      insist { subject["foo"][1] } == "carrera.databits.net"
    end
  end

  describe "dns reverse lookup, not an IP" do
    config <<-CONFIG
      filter {
        dns {
          reverse => "foo"
        }
      }
    CONFIG

    sample({"@fields" => { "foo" => "not.an.ip"}}) do
      insist { subject["foo"] } == "not.an.ip"
    end
  end

  describe "dns resolve lookup, replace (on event.source)" do
    config <<-CONFIG
      filter {
        dns {
          resolve => "@source"
          action => "replace"
        }
      }
    CONFIG

    sample({"@source" => "carrera.databits.net"}) do
      insist { subject.source } == "199.192.228.250"
    end
  end

  describe "dns resolve lookup, replace (on a field)" do
    config <<-CONFIG
      filter {
        dns {
          resolve => "foo"
          action => "replace"
        }
      }
    CONFIG

    sample({"@fields" => { "foo" => "carrera.databits.net"}}) do
      insist { subject["foo"] } == "199.192.228.250"
    end
  end

  describe "dns resolve lookup, skip multi-value" do
    config <<-CONFIG
      filter {
        dns {
          resolve => "foo"
          action => "replace"
        }
      }
    CONFIG

    sample({"@fields" => { "foo" => ["carrera.databits.net", "foo.databits.net"]}}) do
      insist { subject["foo"] } == ["carrera.databits.net", "foo.databits.net"]
    end
  end

  describe "dns resolve lookup, append" do
    config <<-CONFIG
      filter {
        dns {
          resolve => "foo"
          action => "append"
        }
      }
    CONFIG

    sample({"@fields" => { "foo" => "carrera.databits.net"}}) do
      insist { subject["foo"][0] } == "carrera.databits.net"
      insist { subject["foo"][1] } == "199.192.228.250"
    end
  end

  describe "dns resolve lookup, append with multi-value does nothing" do
    config <<-CONFIG
      filter {
        dns {
          resolve => "foo"
          action => "append"
        }
      }
    CONFIG

    sample({"@fields" => { "foo" => ["carrera.databits.net", "foo.databits.net"]}}) do
      insist { subject["foo"] } == ["carrera.databits.net", "foo.databits.net"]
    end
  end

  describe "dns resolve lookup, not a valid hostname" do
    config <<-CONFIG
      filter {
        dns {
          resolve=> "foo"
        }
      }
    CONFIG

    sample({"@fields" => { "foo" => "does.not.exist"}}) do
      insist { subject["foo"] } == "does.not.exist"
    end
  end
end