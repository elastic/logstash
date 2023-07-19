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

describe "Java integration" do
  context "type equivalence" do
    # here we test for both is_a? and case/when usage of the Java types
    # because these are the specific use-cases in our code and the expected
    # behaviour.

    context "Java::JavaUtil::ArrayList" do
      it "should report to be a Ruby Array" do
        expect(Java::JavaUtil::ArrayList.new.is_a?(Array)).to eq(true)
      end

      it "should be class equivalent to Ruby Array" do
        expect do
          case Java::JavaUtil::ArrayList.new
          when Array
            true
          else
            raise
          end
        end.not_to raise_error

        expect(Array === Java::JavaUtil::ArrayList.new).to eq(true)
      end
    end

    context "Java::JavaUtil::LinkedHashMap" do
      it "should report to be a Ruby Hash" do
        expect(Java::JavaUtil::LinkedHashMap.new.is_a?(Hash)).to eq(true)
      end

      it "should be class equivalent to Ruby Hash" do
        expect do
          case Java::JavaUtil::LinkedHashMap.new
          when Hash
            true
          else
            raise
          end
        end.not_to raise_error

        expect(Hash === Java::JavaUtil::LinkedHashMap.new).to eq(true)
      end
    end
  end

  context "Java::JavaUtil::Map" do
    # this is to test the Java 8 Map interface change for the merge method

    let(:merger) {{:a => 1, :b => 2}}
    let(:mergee) {{:b => 3, :c => 4}}

    shared_examples "map merge" do
      it "should support merging" do
        expect(subject.merge(mergee)).to eq({:a => 1, :b => 3, :c => 4})
      end

      it "should return a new hash and not change original hash" do
        expect {subject.merge(mergee)}.to_not change {subject}
      end
    end

    context "with Java::JavaUtil::LinkedHashMap" do
      it_behaves_like "map merge" do
        subject {Java::JavaUtil::LinkedHashMap.new(merger)}
      end
    end

    context "with Java::JavaUtil::HashMap" do
      it_behaves_like "map merge" do
        subject {Java::JavaUtil::HashMap.new(merger)}
      end
    end
  end

  context "Java::JavaUtil::Collection" do
    subject {Java::JavaUtil::ArrayList.new(initial_array)}

    context "when inspecting a list" do
      let(:items) { [:a, {:b => :c}] }
      subject { java.util.ArrayList.new(items) }

      it "should include the contents of the Collection" do
        expect(subject.inspect).to include(items.inspect)
      end

      it "should include the class name" do
        expect(subject.inspect).to include("ArrayList")
      end
    end

    context "when inspecting a set" do
      let(:items) { [:foo, 'bar'] }
      subject { java.util.HashSet.new(items) }

      it "should include the contents" do
        expect(subject.inspect).to include 'bar'
      end

      it "should include the class name" do
        expect(subject.inspect).to include("HashSet")

        expect(java.util.TreeSet.new.inspect).to include("TreeSet")
      end
    end

    context "when deleting a unique instance" do
      let(:initial_array) {["foo", "bar"]}

      it "should return the deleted object" do
        expect(subject.delete("foo")).to eq("foo")
      end

      it "should remove the object to delete" do
        expect {subject.delete("foo")}.to change {subject.to_a}.from(initial_array).to(["bar"])
      end
    end

    context "when deleting multiple instances" do
      let(:initial_array) {["foo", "bar", "foo"]}

      it "should return the last deleted object" do
        expect(subject.delete("foo")).to eq("foo")
      end

      it "should remove all the objects to delete" do
        expect {subject.delete("foo")}.to change {subject.to_a}.from(initial_array).to(["bar"])
      end
    end

    context "when deleting non existing object" do
      let(:initial_array) {["foo", "bar", "foo"]}

      it "should return nil" do
        expect(subject.delete("baz")).to be_nil
      end

      it "should not change the collection" do
        expect {subject.delete("baz")}.to_not change {subject.to_a}
      end

      it "should yield to block when given" do
        expect(subject.delete("baz") {"foobar"}).to eq("foobar")
      end
    end

    context "when deleting on empty collection" do
      let(:initial_array) {[]}

      it "should return nil" do
        expect(subject.delete("baz")).to be_nil
      end

      it "should not change the collection" do
        expect {subject.delete("baz")}.to_not change {subject.to_a}
      end
    end

    context "when intersecting with a Ruby Array" do
      context "using string collection with duplicates and single result" do
        let(:initial_array) {["foo", "bar", "foo"]}

        it "should not change original collection" do
          expect {subject & ["foo"]}.to_not change {subject.to_a}
        end

        it "should return a new array containing elements common to the two arrays, excluding any duplicate" do
          expect((subject & ["foo"]).to_a).to eq(["foo"])
        end
      end

      context "using string collection with duplicates and multiple results" do
        let(:original) {["foo", "bar", "foo", "baz"]}
        let(:target) {["baz", "foo"]}
        let(:result) {["foo", "baz"]}

        it "should return a new array containing elements common to the two arrays, excluding any duplicate and preserve order from the original array" do
          # this is the Ruby contract
          expect(original & target).to eq(result)

          # this should work the same
          expect((Java::JavaUtil::ArrayList.new(original) & target).to_a).to eq(result)
        end
      end

      context "Ruby doc examples" do
        it "should return a new array containing elements common to the two arrays, excluding any duplicate" do
          expect(Java::JavaUtil::ArrayList.new(([1, 1, 3, 5]) & [1, 2, 3]).to_a).to eq([1, 3])
          expect(Java::JavaUtil::ArrayList.new((['a', 'b', 'b', 'z']) & ['a', 'b', 'c']).to_a).to eq(['a', 'b'])
        end
      end
    end

    context "when unioning with a Ruby Array" do
      context "using string collection with duplicates" do
        let(:initial_array) {["foo", "bar", "foo"]}

        it "should not change original collection" do
          expect {subject | ["bar", "baz"]}.to_not change {subject.to_a}
        end

        it "should return a new array by joining excluding any duplicates and preserving the order from the original array" do
          expect((subject | ["bar", "baz"]).to_a).to eq(["foo", "bar", "baz"])
        end

        it "should remove duplicates when joining empty array" do
          expect((subject | []).to_a).to eq(["foo", "bar"])
        end
      end

      context "Ruby doc examples" do
        it "should return a new array containing elements common to the two arrays, excluding any duplicate" do
          expect(Java::JavaUtil::ArrayList.new((["a", "b", "c"]) | ["c", "d", "a"]).to_a).to eq(["a", "b", "c", "d"])
        end
      end
    end

    context "when compacting" do
      context "#compact with nils" do
        let(:initial_array) { [1, 2, 3, nil, nil, 6] }
        it "should remove nil values from a copy" do
          expect(subject.compact).to eq([1, 2, 3, 6])
          expect(subject).to eq([1, 2, 3, nil, nil, 6])
        end
      end

      context "#compact! with nils" do
        let(:initial_array) { [1, 2, 3, nil, nil, 6] }
        it "should remove nil values" do
          expect(subject.compact!).to eq([1, 2, 3, 6])
          expect(subject).to eq([1, 2, 3, 6])
        end

        it "should return the original" do
          expect(subject.compact!.object_id).to eq(subject.object_id)
        end
      end

      context "#compact! without nils" do
        let(:initial_array) { [1, 2, 3, 6] }
        it "should return nil" do
          expect(subject.compact!).to be nil
          expect(subject).to eq([1, 2, 3, 6])
        end
      end
    end
  end

  context "Enumerable implementation" do
    context "Java Map interface should report key with nil value as included" do
      it "should support include? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => nil}).include?("foo")).to eq(true)
      end

      it "should support has_key? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => nil}).has_key?("foo")).to eq(true)
      end

      it "should support member? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => nil}).member?("foo")).to eq(true)
      end

      it "should support key? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => nil}).key?("foo")).to eq(true)
      end
    end

    context "Java Map interface should report key with a value as included" do
      it "should support include? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => 1}).include?("foo")).to eq(true)
      end

      it "should support has_key? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => 1}).has_key?("foo")).to eq(true)
      end

      it "should support member? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => 1}).member?("foo")).to eq(true)
      end

      it "should support key? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => 1}).key?("foo")).to eq(true)
      end
    end

    context "Java Map interface should report non existing key as not included" do
      it "should support include? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => 1})).not_to include("bar")
      end

      it "should support has_key? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => 1}).has_key?("bar")).to eq(false)
      end

      it "should support member? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => 1}).member?("bar")).to eq(false)
      end

      it "should support key? method" do
        expect(Java::JavaUtil::LinkedHashMap.new({"foo" => 1}).key?("bar")).to eq(false)
      end
    end
  end
end
