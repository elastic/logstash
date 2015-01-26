require 'spec_helper'

describe "conditionals" do

  let(:pipeline) { LogStash::Pipeline.new(config.to_s) }

  context "within outputs" do

    describe "having a simple conditional" do
      let(:config) {
        <<-CONFIG
          input {
            generator {
              message => '{"foo":{"bar"},"baz": "quux"}'
              count => 1
            }
          }
          output {
             if [foo] == "bar" {
             stdout { }
          }
        }
      CONFIG
      }

      context"when starting an agent" do
        it "doesn't not fail" do
          expect { pipeline.run }.to_not raise_error
        end
      end

    end
  end

  context "within filters" do

    describe "having a simple conditional" do
      let(:config) { ConfigFactory.filter.add_field("always" => "awesome").
                      if("[foo] == 'bar'").
                        add_field("hello" => "world").
                      elseif("[bar] == 'baz'").
                        add_field("fancy" => "pants").
                      else.
                        add_field("free" => "hugs").
                      endif }

      it "include the default field" do include("always" => "awesome") end

      context "when the if is true" do

        subject      {  sample("foo" => "bar") }

        it "include the if field"  do include("hello" => "world") end
        it "not include the elseif field" do should_not include("fancy", "hugs") end
      end

      context "when the else is true" do

        subject      {  sample("notfoo" => "bar") }

        it "include the else field" do include("free" => "hugs" ) end
        it "not include the elseif field" do should_not include("hello", "fancy") end
      end


      context "when the elseif is true" do

        subject      {  sample("bar" => "baz") }

        it "include the elseif field" do include("fancy" => "pants") end
        it "not include the if field" do should_not include("hello", "free") end
      end

    end

    describe "having nested conditionals" do
      let(:config) { ConfigFactory.filter.
                             if("[nest] == 123").add_field("always" => "awesome").
                             if("[foo] == 'bar'").add_field("hello" => "world").
                             elseif("[bar] == 'baz'").add_field("fancy" => "pants").
                             else.add_field("free" => "hugs").endif.
                             endif }

      context "when the main if is not true" do

        subject { sample(["foo" => "bar", "nest" => 124])  }

        it "add no field" do should_not include("always", "hello", "fancy", "free") end
      end

      context "if the main if is true" do

        it "include the primary if field" do include("always" => "awesome") end

        context "when the nested if is true" do

          subject { sample(["foo" => "bar", "nest" => 123])  }

          it "not include the elseif field" do should_not include("fancy", "free") end
          it "include the nested if field"  do include("hello" => "world") end
        end

        context "when the nested else is true" do
          subject { sample(["notfoo" => "bar", "nest" => 123])  }

          it "not include the if field" do should_not include("hello") end
          it "not include the elseif field" do should_not include("fancy") end
          it "include the else field" do include("free" => "hugs") end
        end

        context "when the nested elseif is true" do

          subject { sample(["bar" => "baz", "nest" => 123])  }

          it "not include the else field" do should_not include("free") end
          it "not include the if field" do should_not include("hello") end
          it "add the elseif field" do include("fancy" => "pants") end
        end
      end
    end

      describe "when comparing two fields" do
        let(:config) { ConfigFactry.filter.if("[foo] == [bar]").
                       add_tag("woot").
                       endif }

        subject { sample(["foo" => 123, "bar" => 123])  }

        context "when the if is true" do
          it "include the if tag" do
            include("tags" => ["woot"])
          end
        end
      end

    describe "when a new events is created" do

      let(:config)  { ConfigFactory.filter.if("[type] == 'original'").
                                           clones('clone').
                                           add_field("cond1" => "true").
                                           else.add_field("cond2" => "true").
                                           endif }

      subject { sample("type" => "original").to_a }

      it "the first message has type original" do
        expect(subject[0]).to include("type" => "original")
      end

      it "the first message has a new field" do
        expect(subject[0]).to include("cond1" => "true")
      end

      it "has a message with type clone" do
        expect(subject[1]).to include("type" => "clone")
      end

    end
  end
end
