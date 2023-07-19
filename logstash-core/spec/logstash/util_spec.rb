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

require 'spec_helper'

require "logstash/util"

class ClassNameTest
end

module TestingClassName
  class TestKlass
  end
end

describe LogStash::Util do
  subject { described_class }

  context "stringify_keys" do
    it "should convert hash symbol keys to strings" do
      expect(LogStash::Util.stringify_symbols({:a => 1, "b" => 2})).to eq({"a" => 1, "b" => 2})
    end

    it "should keep non symbolic hash keys as is" do
      expect(LogStash::Util.stringify_symbols({1 => 1, 2.0 => 2})).to eq({1 => 1, 2.0 => 2})
    end

    it "should convert inner hash keys to strings" do
      expect(LogStash::Util.stringify_symbols({:a => 1, "b" => {:c => 3}})).to eq({"a" => 1, "b" => {"c" => 3}})
      expect(LogStash::Util.stringify_symbols([:a, 1, "b", {:c => 3}])).to eq(["a", 1, "b", {"c" => 3}])
    end

    it "should convert hash symbol values to strings" do
      expect(LogStash::Util.stringify_symbols({:a => :a, "b" => :b})).to eq({"a" => "a", "b" => "b"})
    end

    it "should convert array symbol values to strings" do
      expect(LogStash::Util.stringify_symbols([1, :a])).to eq([1, "a"])
    end

    it "should convert inner array symbol values to strings" do
      expect(LogStash::Util.stringify_symbols({:a => [1, :b]})).to eq({"a" => [1, "b"]})
      expect(LogStash::Util.stringify_symbols([:a, [1, :b]])).to eq(["a", [1, "b"]])
    end
  end

  context "deep_clone" do
    it "correctly clones a LogStash::Timestamp" do
      timestamp = LogStash::Timestamp.now
      expect(LogStash::Util.deep_clone(timestamp).inspect).to eq(timestamp.inspect)
    end
  end

  describe ".class_name" do
    context "when the class is a top level class" do
      let(:klass) { ClassNameTest.new }

      it "returns the name of the class" do
        expect(subject.class_name(klass)).to eq("ClassNameTest")
      end
    end

    context "when the class is nested inside modules" do
      let(:klass) { TestingClassName::TestKlass.new }

      it "returns the name of the class" do
        expect(subject.class_name(klass)).to eq("TestKlass")
      end
    end
  end

  describe ".get_thread_id" do
    it "returns native identifier" do
      thread_id = LogStash::Util.get_thread_id(Thread.current)
      expect(thread_id).to be_a Integer
      expect(thread_id).to eq(java.lang.Thread.currentThread.getId)
    end
  end
end
