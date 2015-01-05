require 'spec_helper'

describe "operators" do

  let(:defs)   { ConfigFactory.filter.if("%s").add_tag("success").
                                else.add_tag("failure").
                                endif
                }
  describe "value as expression" do

    context "with a placeholder message" do
      it "add the success tag to any message" do
        config    = defs % ["[message]"]
        expect(sample_from("apple", config)).to include("tags" => ["success"])
      end

      it "add the failure tag to any message" do
        config    = defs % ["[missing]"]
        expect(sample_from("apple", config)).to include("tags" => ["failure"])
      end
    end

    context "when using logic operators" do

      describe "and" do
        it "add the success tag for true expressions" do
          config    = defs % ["[message] and [message]" ]
          expect(sample_from("apple", config)).to include("tags" => ["success"])
        end

        it "add the failure tag for false expressions" do
          config    = defs % ["[message] and ![message]" ]
          expect(sample_from("apple", config)).to include("tags" => ["failure"])
        end

        it "add the failure tag for double negated expressions" do
          config    = defs % ["![message] and ![message]" ]
          expect(sample_from("apple", config)).to include("tags" => ["failure"])
        end
      end

      describe "or" do
        it "add the success tag for true expressions" do
          config    = defs % ["[message] or [message]" ]
          expect(sample_from("apple", config)).to include("tags" => ["success"])
        end

        it "add the success tag for one negated term expressions" do
          config    = defs % ["[message] or ![message]" ]
          expect(sample_from("apple", config)).to include("tags" => ["success"])
        end

        it "add the failure tag for double negated expressions" do
          config    = defs % ["![message] or ![message]" ]
          expect(sample_from("apple", config)).to include("tags" => ["failure"])
        end
      end

    end

    context "with field references" do

      context "having spaces in the criteria" do

        it "add the success tag when using a field" do
          config    = defs % ["[field with space]"]
          expect(sample_from({"field with space" => "hurray"}, config)).to include("tags" => ["success"])
        end

        it "add the success tag when using an eq comparison" do
          patterns = ["[field with space] == 'hurray'"]
          config   = defs % patterns
          expect(sample_from({"field with space" => "hurray"}, config)).to include("tags" => ["success"])
        end

        it "add the success tag when using nested fields" do
          patterns = ["[nested field][reference with][some spaces] == 'hurray'"]
          config   = defs % patterns
          event    = {"nested field" => { "reference with" => { "some spaces" => "hurray" } } }
          expect(sample_from(event, config)).to include("tags" => ["success"])
        end

      end
    end

  end
  end
