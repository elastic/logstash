# encoding: utf-8
require "spec_helper"
require "logstash/filters/dns"
require "resolv"

describe LogStash::Filters::DNS do
  before(:each) do
    allow_any_instance_of(Resolv).to receive(:getaddress).with("carrera.databits.net").and_return("199.192.228.250")
    allow_any_instance_of(Resolv).to receive(:getaddress).with("does.not.exist").and_raise(Resolv::ResolvError)
    allow_any_instance_of(Resolv).to receive(:getaddress).with("nonexistanthostname###.net").and_raise(Resolv::ResolvError)
    allow_any_instance_of(Resolv).to receive(:getname).with("199.192.228.250").and_return("carrera.databits.net")
    allow_any_instance_of(Resolv).to receive(:getname).with("127.0.0.1").and_return("localhost")
    allow_any_instance_of(Resolv).to receive(:getname).with("128.0.0.1").and_raise(Resolv::ResolvError)
    allow_any_instance_of(Resolv).to receive(:getname).with("199.192.228.250").and_return("carrera.databits.net")
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

    sample("foo" => "199.192.228.250") do
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

    sample("foo" => "199.192.228.250") do
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

    sample("foo" => "not.an.ip") do
      insist { subject["foo"] } == "not.an.ip"
    end
  end

  describe "dns resolve lookup, replace" do
    config <<-CONFIG
      filter {
        dns {
          resolve => ["host"]
          action => "replace"
          add_tag => ["success"]
        }
      }
    CONFIG

    sample("host" => "carrera.databits.net") do
      insist { subject["host"] } == "199.192.228.250"
      insist { subject["tags"] } == ["success"]
    end
  end

  describe "dns fail resolve lookup, don't add tag" do
    config <<-CONFIG
      filter {
        dns {
          resolve => ["host1", "host2"]
          action => "replace"
          add_tag => ["success"]
        }
      }
    CONFIG

    sample("host1" => "carrera.databits.net", "host2" => "nonexistanthostname###.net") do
      insist { subject["tags"] }.nil?
      insist { subject["host1"] } == "carrera.databits.net"
      insist { subject["host2"] } == "nonexistanthostname###.net"
    end
  end

  describe "dns resolves lookups, adds tag" do
    config <<-CONFIG
      filter {
        dns {
          resolve => ["host1", "host2"]
          action => "replace"
          add_tag => ["success"]
        }
      }
    CONFIG

    sample("host1" => "carrera.databits.net", "host2" => "carrera.databits.net") do
      insist { subject["tags"] } == ["success"]
    end
  end

  describe "dns resolves and reverses, fails last, no tag" do
    config <<-CONFIG
      filter {
        dns {
          resolve => ["host1"]
          reverse => ["ip1", "ip2"]
          action => "replace"
          add_tag => ["success"]
        }
      }
    CONFIG

    sample("host1" => "carrera.databits.net",
           "ip1" => "127.0.0.1",
           "ip2" => "128.0.0.1") do
      insist { subject["tags"] }.nil?
      insist { subject["host1"] } == "carrera.databits.net"
      insist { subject["ip1"] } == "127.0.0.1"
      insist { subject["ip2"] } == "128.0.0.1"
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

    sample("foo" => "carrera.databits.net") do
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

    sample("foo" => ["carrera.databits.net", "foo.databits.net"]) do
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

    sample("foo" => "carrera.databits.net") do
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

    sample("foo" => ["carrera.databits.net", "foo.databits.net"]) do
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

    sample("foo" => "does.not.exist") do
      insist { subject["foo"] } == "does.not.exist"
    end
  end
end
