# encoding: utf-8

require "test_utils"
require "logstash/filters/dns"
require "resolv"

describe LogStash::Filters::DNS do
  extend LogStash::RSpec

  describe "dns reverse lookup, no target" do
    config <<-CONFIG
      filter {
        dns {
          source => "host"
        }
      }
    CONFIG

    address = Resolv.new.getaddress("aspmx.l.google.com")
    expected = Resolv.new.getname(address)
    sample("host" => address) do
      insist { subject["host"] } == address
      insist { subject["dns"] } == expected
    end
  end

  describe "dns lookup, with target" do
    config <<-CONFIG
      filter {
        dns {
          source => "foo"
          target => "bar"
        }
      }
    CONFIG

    name = Resolv.new.getname("8.8.8.8")
    expected = Resolv.new.getaddress(name)
    sample("foo" => name) do
      insist { subject["foo"] } == name
      insist { subject["bar"] } == expected
    end
  end

  describe "dns lookup, empty target" do
    config <<-CONFIG
      filter {
        dns {
          source => "foo"
          target => ""
        }
      }
    CONFIG

    name = Resolv.new.getname("8.8.8.8")
    expected = Resolv.new.getaddress(name)
    sample("foo" => name) do
      insist { subject["foo"] } == name
      insist { subject["dns"] } == expected
    end
  end

  describe "dns lookup, NXDOMAIN, no target" do
    config <<-CONFIG
      filter {
        dns {
          source => "foo"
        }
      }
    CONFIG

    sample("foo" => "doesnotexist.invalid.topleveldomain") do
      insist { subject["foo"] } == "doesnotexist.invalid.topleveldomain"
      insist { subject["dns"] }.nil?
    end
  end

  describe "dns lookup, NXDOMAIN, with target" do
    config <<-CONFIG
      filter {
        dns {
          source => "foo"
          target => "bar"
        }
      }
    CONFIG

    sample("foo" => "doesnotexist.invalid.topleveldomain") do
      insist { subject["foo"] } == "doesnotexist.invalid.topleveldomain"
      insist { subject["bar"] }.nil?
    end
  end

  # Tests for the source/target options
  describe "dns reverse lookup, no target" do
    config <<-CONFIG
      filter {
        dns {
          source => "host"
        }
      }
    CONFIG

    sample("host" => "199.192.228.250") do
      insist { subject["host"] } == "199.192.228.250"
      insist { subject["dns"] } == "carrera.databits.net"
    end
  end

  describe "dns lookup, with target" do
    config <<-CONFIG
      filter {
        dns {
          source => "foo"
          target => "bar"
        }
      }
    CONFIG

    sample("foo" => "199.192.228.250") do
      insist { subject["foo"] } == "199.192.228.250"
      insist { subject["bar"] } == "carrera.databits.net"
    end
  end

  describe "dns lookup, NXDOMAIN, no target" do
    config <<-CONFIG
      filter {
        dns {
          source => "foo"
        }
      }
    CONFIG

    sample("foo" => "doesnotexist.invalid.topleveldomain") do
      insist { subject["foo"] } == "doesnotexist.invalid.topleveldomain"
      insist { subject["dns"] } == nil
    end
  end

  describe "dns lookup, NXDOMAIN, with target" do
    config <<-CONFIG
      filter {
        dns {
          source => "foo"
          target => "bar"
        }
      }
    CONFIG

    sample("foo" => "doesnotexist.invalid.topleveldomain") do
      insist { subject["foo"] } == "doesnotexist.invalid.topleveldomain"
      insist { subject["bar"] } == nil
    end
  end
end
