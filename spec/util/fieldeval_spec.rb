require "spec_helper"
require "logstash/util/fieldreference"

describe LogStash::Util::FieldReference, :if => true do

  context "using simple accessor" do

    let(:key)  { "hello" }
    let(:data) { { "hello" => "world" } }

    let(:m)    { eval(subject.compile(key)) }

    it "retrieve value" do
      expect(m.call(data)).to eq("world")
    end

    it "handle delete in block" do
      m.call(data) { |obj, key| obj.delete(key) }
      expect(data).to be_empty
    end

    context "in assignment" do

      let(:data) { {} }

      it "return the assigned value in blocks" do
        assign = m.call(data) { |obj, key| obj[key] = "things" }
        expect(assign).to eq("things")
      end

      it "updates the internal hash" do
        m.call(data) { |obj, key| obj[key] = "things" }
        expect(data).to include("hello" => "things")
      end

      context "using set" do

        it "return the assigned value" do
          assigned =  subject.set(key, "things", data)
          expect(assigned).to eq("things")
        end

        it "udpates the internal hash" do
          subject.set(key, "things", data)
          expect(data).to include("hello" => "things")
        end
      end

    end
  end

  context "using accessor path" do

    let(:key) { "[hello]" }
    let(:m)   { eval(subject.compile(key)) }
    let(:data) { { "hello" =>  "world" } }

    it "retrieve shallow value" do
      expect(m.call(data)).to eq("world")
    end

    context "using set" do

      let(:data) {{}}

      it "return the assigned value" do
        assigned = subject.set(key, "foo", data)
        expect(assigned).to eq("foo")
      end

      it "update the internal hash" do
        subject.set(key, "foo", data)
        expect(data).to include("hello" => "foo")
      end

    end

    context "with deep values" do

      let(:key) { "[hello][world]" }
      let(:data) { { "hello" => { "world" => "foo", "bar" => "baz" } } }

      it "retrieve deep value" do
        expect(m.call(data)).to eq("foo")
      end

      it "handle delete in block" do
        m.call(data) { |obj, key| obj.delete(key) }
        expect(data["hello"]).to_not include("world" => "foo")
      end

      context "using set" do
        let(:data) {{}}

        it "return the assigned value" do
          assigned = subject.set(key, "foo", data)
          expect(assigned).to eq("foo")
        end
        it "update the internal hash" do
          subject.set(key, "foo", data)
          expect(data).to include( "hello" => { "world" => "foo" } )
        end
      end

      context "with assignment" do

        let(:data) {{}}

        it "not handle assignment in block" do
          assign = m.call(data) { |obj, key| obj[key] = "things" }
          expect(assign).to be_nil
        end

        it "doesn't not affect the data hash" do
          m.call(data) { |obj, key| obj[key] = "things" }
          expect(data).to be_empty
        end
      end
    end

    context "with arrays" do

      let(:data) { { "hello" => { "world" => ["a", "b"], "bar" => "baz" } } }
      let(:base_key) { "[hello][world]" }

      it "retrieve the first array item" do
        m = eval(subject.compile("#{base_key}[0]"))
        expect(m.call(data)).to eq("a")
      end

      it "retrieve the second array item" do
        m = eval(subject.compile("#{base_key}[1]"))
        expect(m.call(data)).to eq("b")
      end
    end
  end
end
