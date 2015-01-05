# encoding: utf-8

require "spec_helper"
require "logstash/util/accessors"

describe LogStash::Util::Accessors, :if => true do

  let(:data)      { {} }
  let(:accessors) { LogStash::Util::Accessors.new(data)}

  context "using simple field" do

    context "get value" do
      it "accepts with a word key" do
        data = { "hello" => "world" }
        accessors = LogStash::Util::Accessors.new(data)
        expect(accessors.get("hello")).to eq(data["hello"])
      end

      it "accepts a key with spaces" do
        data = { "hel lo" => "world" }
        accessors = LogStash::Util::Accessors.new(data)
        expect(accessors.get("hel lo")).to eq(data["hel lo"])
      end

      it "accepts a numeric key string" do
        data = { "1" => "world" }
        accessors = LogStash::Util::Accessors.new(data)
        expect(accessors.get("1")).to eq(data["1"])
      end
    end

    context "deletion" do

      let(:data) { { "simple" => "things"} }

      it "return the deleted value" do
        expect(accessors.del("simple")).to eq("things")
      end

      it "handle deletion" do
        accessors.del("simple")
        expect(data).to be_empty
      end
    end

    context "set" do

      let(:str)  { "simple" }

      context "string value" do
        it "return the value field" do
          expect( accessors.set(str, "things")).to eq("things")
        end
        it "update the hash value" do
          accessors.set(str, "things")
          expect(data).to include("simple" => "things")
        end
      end

      context "array value" do
        it "return the value field" do
          expect(accessors.set(str, ["foo", "bar"])).to eq(["foo", "bar"])
        end
        it "update the hash value" do
          accessors.set(str, ["foo", "bar"])
          expect(data).to include("simple" => ["foo", "bar"])
        end
      end
    end
  end

  context "using field path" do

    context "get value" do

      it "accepts string value of word key" do
        data = { "hello" =>  "world" }
        accessors = LogStash::Util::Accessors.new(data)
        expect(accessors.get("[hello]")).to eq("world")
      end

      it "accepts string value of key with spaces" do
        data = { "hel lo" =>  "world" }
        accessors = LogStash::Util::Accessors.new(data)
        expect(accessors.get("[hel lo]")).to eq("world")
      end

      it "accepts string value of numeric key string" do
        data = { "1" =>  "world" }
        accessors = LogStash::Util::Accessors.new(data)
        expect(accessors.get("[1]")).to eq("world")
      end

      it "accepts deep string value" do
        data = { "hello" => { "world" => "foo", "bar" => "baz" } }
        accessors = LogStash::Util::Accessors.new(data)
        expect(accessors.get("[hello][world]")).to eq(data["hello"]["world"])
      end

      it "return nil when getting a non-existant field (no side effects)" do
        data = { }
        accessors = LogStash::Util::Accessors.new(data)
        accessors.get("[hello][world]")
        expect(data).to be_empty
      end
   end

    context "delete" do

      let(:key)  { "[hello][world]" }
      let(:data) { { "hello" => { "world" => "foo", "bar" => "baz" } } }

      it "return the value object" do
        expect(accessors.del(key)).to eq("foo")
      end

      it "remove the kv pair" do
        accessors.del(key)
        expect(data["hello"]).to include("bar" => "baz")
      end
    end

    context "set" do
      let(:key)  { "[hello]" }

      it "returns the set value" do
        expect(accessors.set(key, "foo")).to eq("foo")
      end

      it "adds the new pair to the hash" do
        accessors.set(key, "foo")
        expect(data).to include("hello" => "foo")
      end

      context "with strict set" do

        it "returns the set value" do
          expect(accessors.strict_set(key, "foo")).to eq("foo")
        end

        it "adds the new pair to the hash" do
          accessors.strict_set(key, "foo")
          expect(data).to include("hello" => "foo")
        end
      end

      context "with a deep value" do

        let(:key)  { "[hello][world]" }

        it "returns the set value" do
          expect(accessors.set(key, "foo")).to eq("foo")
        end

        it "adds the new pair to the hash" do
          accessors.set(key, "foo")
          expect(data).to include("hello" => { "world" => "foo" })
        end

        context "with an array value" do

          it "returns the set value" do
            expect(accessors.set(key, ["foo", "bar"])).to include("foo", "bar")
          end

          it "adds the new pair to the hash" do
            accessors.set(key, ["foo", "bar"])
            expect(data).to include("hello" => { "world" => ["foo", "bar"] })
          end

          context "using strict_set" do
            it "returns the set value" do
              expect(accessors.strict_set(key, ["foo", "bar"])).to include("foo", "bar")
            end

            it "adds the new pair to the hash" do
              accessors.strict_set(key, ["foo", "bar"])
              expect(data).to include("hello" => { "world" => ["foo", "bar"] })
            end
          end

          context "elements within array value" do
            let(:key)  {  "[hello][0]" }
            let(:data) { {"hello" => ["foo", "bar"]} }

            it "returns the set value" do
              expect(accessors.set(key, "world")).to eq("world")
            end

            it "adds the new pair to the hash" do
              accessors.strict_set(key, "world")
              expect(data).to include("hello" => ["world", "bar"])
            end

          end
        end
      end
    end

    context "with array items" do

      let(:data) { { "hello" => { "world" => ["a", "b"], "bar" => "baz" } } }

      it "retrieve the first item" do
        expect(accessors.get("[hello][world][0]")).to eq("a")
      end

      it "retrieve the second item" do
        expect(accessors.get("[hello][world][1]")).to eq("b")
      end

      context "when containing a hash" do
        let(:data) { { "hello" => { "world" => [ { "a" => 123 }, { "b" => 345 } ], "bar" => "baz" } } }

        it "retrieve the first item" do
          expect(accessors.get("[hello][world][0][a]")).to eq(123)
        end

        it "retrieve the second item" do
          expect(accessors.get("[hello][world][1][b]")).to eq(345)
        end
      end

      context "handle delete" do

        let(:key)  { "[geocoords][0]" }
        let(:data) { { "geocoords" => [4, 2] } }

        it "returns the deleted value" do
          expect(accessors.del(key)).to eq(4)
        end

        it "remove the value from the hash" do
          accessors.del(key)
          expect(data).to include("geocoords" => [2])
        end
      end
    end
  end

  context "using invalid encoding" do
    let(:key) { "[hello]" }

    it "strinct_set raise on non UTF-8 string encoding" do
      value = "foo".encode("US-ASCII")
      expect { accessors.strict_set(key, value) }.to raise_error
    end

    it "strinct_set raise on non UTF-8 string encoding in array" do
      value = ["foo", "bar".encode("US-ASCII")]
      expect { accessors.strict_set(key, value) }.to raise_error
    end

    it "strinct_set raise on invalid UTF-8 string encoding" do
      value = "foo \xED\xB9\x81\xC3"
      expect { accessors.strict_set(key, value ) }.to raise_error
    end

    it "strinct_set raise on invalid UTF-8 string encoding in array" do
      value = ["foo", "bar \xED\xB9\x81\xC3"]
      expect { accessors.strict_set(key, value) }.to raise_error
    end
  end
end
