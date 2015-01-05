require 'spec_helper'

describe "operators" do

  let(:pipeline) {LogStash::Pipeline.new(config.to_s)}

  describe "the in operator" do
    let(:config) { ConfigFactory.filter.if("[foo] in [foobar]").add_tag("field in field").endif.
                                        if('[foo] in "foo"').add_tag("field in string").endif.
                                        if('"hello" in [greeting]').add_tag("string in field").endif.
                                        if('[foo] in ["hello", "world", "foo"]').add_tag("field in list").endif.
                                        if('[missing] in [alsomissing]').add_tag("shouldnotexist").endif.
                                        if('!("foo" in ["hello", "world"])').add_tag("shouldexist").endif }
    subject      {   sample("foo" => "foo", "foobar" => "foobar", "greeting" => "hello world") }

    it "add the filds that meet the filter crieria" do
      is_expected.to include("tags" => ["field in field", "field in string", "string in field", "field in list", "shouldexist"])
    end

    it "does not add values or cretiras not meet" do
      is_expected.not_to include("tags" => ["shouldnotexist"])
    end
  end

  describe "the not in operator" do
    let(:event)  { {"foo" => "foo", "somelist" => [ "one", "two" ],
                    "foobar" => "foobar", "greeting" => "hello world",
                    "tags" => [ "fancypantsy" ]} }
    let(:config) { ConfigFactory.filter.if('"foo" not in "baz"').add_tag("baz").endif.
                                        if('"foo" not in "foo"').add_tag("foo").endif.
                                        if('!("foo" not in "foo")').add_tag("notfoo").endif.
                                        if('"foo" not in [somelist]').add_tag("notsomelist").endif.
                                        if('"one" not in [somelist]').add_tag("somelist").endif.
                                        if('"foo" not in [alsomissing]').add_tag("no string in missing field").endif }
    subject      { sample(event) }

    it "add the filds that meet the filter crieria" do
       include("tags" => ["fancypantsy", "baz", "notfoo", "notsomelist", "no string in missing field"])
    end

    it "does not add values or cretiras not meet" do
      should_not include("tags" => ["somelist", "foo"])
    end
  end

    describe "operators" do
      let(:defs)   { ConfigFactory.filter.if("%s").add_tag("success").
                                          else.add_tag("failure").
                                          endif }
      let(:config) { defs % [expression]}

      context "operator equal" do
      let (:expression) { "[message] == 'sample'"}

      it "add the success tag if the critieria is meet" do
        expect(sample("sample")).to include("tags" => ["success"])
      end

      it "add the failure tag if the critieria is not meet" do
        expect(sample("different")).to include("tags" => ["failure"])
      end
    end

    context "operator not equal" do
      let (:expression) { "[message] != 'sample'"}

      it "add the success tag if the critieria is meet" do
        expect(sample("different")).to include("tags" => ["success"])
      end

      it "add the failure tag if the critieria is not meet" do
        expect(sample("sample")).to include("tags" => ["failure"])
      end
    end

    context "operator lt" do
      let (:expression) { "[message] < 'sample'"}

      it "add the success tag if the critieria is meet" do
        expect(sample("apple")).to include("tags" => ["success"])
      end

      it "add the failure tag if the critieria is not meet" do
        expect(sample("zebra")).to include("tags" => ["failure"])
      end
    end

    context "operator gt" do
      let (:expression) { "[message] > 'sample'"}

      it "add the success tag if the critieria is meet" do
        expect(sample("zebra")).to include("tags" => ["success"])
      end

      it "add the failure tag if the critieria is not meet" do
        expect(sample("apple")).to include("tags" => ["failure"])
      end
    end

    context "operator lte" do
      let (:expression) { "[message] <= 'sample'"}

      it "add the success tag if the critieria is meet" do
        expect(sample("apple")).to include("tags" => ["success"])
      end

      it "add the sucess tag if the message is equal" do
        expect(sample("sample")).to include("tags" => ["success"])
      end

      it "add the failure tag if the critieria is not meet" do
        expect(sample("zebra")).to include("tags" => ["failure"])
      end
    end

    context "operator gte" do
      let (:expression) { "[message] >= 'sample'"}

      it "add the success tag if the critieria is meet" do
        expect(sample("zebra")).to include("tags" => ["success"])
      end

      it "add the sucess tag if the message is equal" do
        expect(sample("sample")).to include("tags" => ["success"])
      end

      it "add the failure tag if the critieria is not meet" do
        expect(sample("apple")).to include("tags" => ["failure"])
      end
    end

    context "operator match" do
      let (:expression) { "[message] =~ /sample/ "}

      it "add the success tag if the critieria is meet" do
        expect(sample("some sample")).to include("tags" => ["success"])
      end

      it "add the sucess tag if the message is equal" do
        expect(sample("sample")).to include("tags" => ["success"])
      end

      it "add the failure tag if the critieria is not meet" do
        expect(sample("apple")).to include("tags" => ["failure"])
      end
    end

    context "operator not match" do
      let (:expression) { "[message] !~ /sample/ "}

      it "add the success tag if the critieria is meet" do
        expect(sample("apple")).to include("tags" => ["success"])
      end

      it "add the failure tag for the exact message" do
        expect(sample("sample")).to include("tags" => ["failure"])
      end

      it "add the failure tag if the critieria is containt in the message" do
        expect(sample("some sample")).to include("tags" => ["failure"])
      end
    end

  end
end
