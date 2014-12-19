require 'spec_helper'

describe "conditionals" do

  let(:pipeline) {LogStash::Pipeline.new(config)}

  context "in outputs" do

    describe "simple" do
      let(:config) { load_fixtures('conditionals/in_output.conf') }

      it "doesn't not fail raising an exeption starting an agent" do
        expect { pipeline.run }.to_not raise_error
      end

    end
  end

  context "in filters" do

    describe "simple" do
      let(:config) { load_fixtures('conditionals/in_filter.conf') }

      context "first conditional meet" do

        subject      {  sample("foo" => "bar") }

        it "by default it add a new field" do include("always" => "awesome") end

        it "add a new field when conditional is meet" do include("hello" => "world") end

        it "does not add a new field, when the conditional is not reach" do
          should_not include("fancy", "free")
        end
      end

      context "last else conditional meet" do

        subject      {  sample("notfoo" => "bar") }

        it ("by default it add a new field") { include("always" => "awesome" ) }

        it ("add a new field when conditional is meet") { include("free" => "hugs" ) }

        it "does not add a new field, when the conditional is not reach" do
          should_not include("hello", "fancy")
        end
      end


      context "an elseif conditional meet" do

        subject      {  sample("bar" => "baz") }

        it ("by default it add a new field") { include("always" => "awesome") }

        it ("does not add a new field, when the conditional is false") { include("fancy" => "pants") }

        it "does not add a new field, when the conditional is not reach" do
          should_not include("hello", "free")
        end
      end

    end

    describe "nested" do
      let(:config) { load_fixtures("conditionals/nested.conf") }

      context "no crietria meet" do
        subject { sample(["foo" => "bar", "nest" => 124])  }

        it "meet no crieria at all" do
          should_not include("always", "hello", "fancy", "free")
        end
      end

      context "nested crieria meet" do
        subject { sample(["foo" => "bar", "nest" => 123])  }

        it "does not add unmeet criteria" do
          should_not include("fancy", "free")
        end

        it "add positive conditionals" do
          include("always" => "awesome", "hello" => "world")
        end

      end

      context "nested crieria meet with else" do
        subject { sample(["notfoo" => "bar", "nest" => 123])  }

        it "does not add unmeet criteria" do
          should_not include("fancy", "hello")
        end

        it "add positive conditionals" do
          include("always" => "awesome", "free" => "hugs")
        end

      end

      context "nested crieria meet with elseif" do
        subject { sample(["bar" => "baz", "nest" => 123])  }

        it "does not add unmeet criteria" do
          should_not include("free", "hello")
        end

        it "add positive conditionals" do
          include("always" => "awesome", "fancy" => "pants")
        end

      end
    end

    describe "comparing two fields" do
      let(:config) { load_fixtures("conditionals/two_fields.conf") }
      subject { sample(["foo" => 123, "bar" => 123])  }

      it "add the fields that meet the filter crieria" do
        include("tags" => ["woot"])
      end
    end

    describe "new events created from root" do

      let(:config) { load_fixtures('events/new_events_from_root.conf') }
      subject { sample("type" => "original").to_a }

      it "returns an array of events" do
        expect(subject).to be_an(Array)
      end

      it "has a first event with type original" do
        expect(subject[0]).to include("type" => "original")
      end

      it "has a first event with a new property" do
        expect(subject[0]).to include("cond1" => "true")
      end

      it "has a second event with type cloned" do
        expect(subject[1]).to include("type" => "clone")
      end

    end
  end
end
