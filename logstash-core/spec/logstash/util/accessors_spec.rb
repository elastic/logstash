# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "spec_helper"

# this is to skip specs when running agains an alternate logstash-core-event implementation
# that does not define the Accessors class. For example, in logstash-core-event-java
# the Accessors class does not exists in the Ruby namespace.
class_exists = begin
  require "logstash/util/accessors"
  true
rescue LoadError
  false
end

describe "LogStash::Util::Accessors", :if => class_exists do
  context "using simple field" do
    it "should get value of word key" do
      str = "hello"
      data = { "hello" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get(str)).to eq(data[str])
    end

    it "should get value of key with spaces" do
      str = "hel lo"
      data = { "hel lo" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get(str)).to eq(data[str])
    end

    it "should get value of numeric key string" do
      str = "1"
      data = { "1" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get(str)).to eq(data[str])
    end

    it "should handle delete" do
      str = "simple"
      data = { "simple" => "things" }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.del(str)).to eq("things")
      expect(data).to be_empty
    end

    it "should handle delete on non-existent field" do
      str = "[foo][bar]"
      data = { "hello" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.del(str)).to be_nil
      expect(data).not_to be_empty
      # assert no side effects
      expect(accessors.get("foo")).to be_nil
      expect(accessors.get("hello")).to eq("world")
    end

    it "should set string value" do
      str = "simple"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.set(str, "things")).to eq("things")
      expect(data).to eq({ "simple" => "things" })
    end

    it "should set array value" do
      str = "simple"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.set(str, ["foo", "bar"])).to eq(["foo", "bar"])
      expect(data).to eq({ "simple" => ["foo", "bar"]})
    end
  end

  context "using field path" do
    it "should get shallow string value of word key" do
      str = "[hello]"
      data = { "hello" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get(str)).to eq("world")
    end

    it "should get shallow string value of key with spaces" do
      str = "[hel lo]"
      data = { "hel lo" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get(str)).to eq("world")
    end

    it "should get shallow string value of numeric key string" do
      str = "[1]"
      data = { "1" => "world" }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get(str)).to eq("world")
    end

    it "should get deep string value" do
      str = "[hello][world]"
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get(str)).to eq(data["hello"]["world"])
    end

    it "should return nil when getting a non-existant field (with no side-effects on original data)" do
      str = "[hello][world]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get(str)).to be_nil
      expect(data).to be_empty
      expect(accessors.set(str, "foo")).to eq("foo")
      expect(data).to eq({ "hello" => {"world" => "foo"} })
    end

    it "should handle delete" do
      str = "[hello][world]"
      data = { "hello" => { "world" => "foo", "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.del(str)).to eq("foo")

      # Make sure the "world" key is removed.
      expect(data["hello"]).to eq({ "bar" => "baz" })
    end

    it "should set shallow string value" do
      str = "[hello]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.set(str, "foo")).to eq("foo")
      expect(data).to eq({ "hello" => "foo" })
    end

    it "should set deep string value" do
      str = "[hello][world]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.set(str, "foo")).to eq("foo")
      expect(data).to eq({ "hello" => { "world" => "foo" } })
    end

    it "should set deep array value" do
      str = "[hello][world]"
      data = {}
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.set(str, ["foo", "bar"])).to eq(["foo", "bar"])
      expect(data).to eq({ "hello" => { "world" => ["foo", "bar"] } })
    end

    it "should set element within array value" do
      str = "[hello][0]"
      data = {"hello" => ["foo", "bar"]}
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.set(str, "world")).to eq("world")
      expect(data).to eq({"hello" => ["world", "bar"]})
    end

    it "should retrieve array item" do
      data = { "hello" => { "world" => ["a", "b"], "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get("[hello][world][0]")).to eq(data["hello"]["world"][0])
      expect(accessors.get("[hello][world][1]")).to eq(data["hello"]["world"][1])
    end

    it "should retrieve array item containing hash" do
      data = { "hello" => { "world" => [{ "a" => 123 }, { "b" => 345 }], "bar" => "baz" } }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.get("[hello][world][0][a]")).to eq(data["hello"]["world"][0]["a"])
      expect(accessors.get("[hello][world][1][b]")).to eq(data["hello"]["world"][1]["b"])
    end

    it "should handle delete of array element" do
      str = "[geocoords][0]"
      data = { "geocoords" => [4, 2] }
      accessors = LogStash::Util::Accessors.new(data)
      expect(accessors.del(str)).to eq(4)
      expect(data).to eq({ "geocoords" => [2] })
    end
  end
end
