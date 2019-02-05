# encoding: utf-8
require "spec_helper"
require "logstash/settings"

describe LogStash::Setting::ArrayCoercible do
  subject { described_class.new("option", element_class, value) }
  let(:value) { [ ] }
  let(:element_class) { Object }

  context "when given a non array value" do
    let(:value) { "test" }
    describe "the value" do
      it "is converted to an array with that single element" do
        expect(subject.value).to eq(["test"])
      end
    end
  end

  context "when given an array value" do
    let(:value) { ["test"] }
    describe "the value" do
      it "is not modified" do
        expect(subject.value).to eq(value)
      end
    end
  end

  describe "initialization" do
    subject { described_class }
    let(:element_class) { Integer }
    context "when given values of incorrect element class" do
      let(:value) { "test" }

      it "will raise an exception" do
        expect { described_class.new("option", element_class, value) }.to raise_error(ArgumentError)
      end
    end
    context "when given values of correct element class" do
      let(:value) { 1 }

      it "will not raise an exception" do
        expect { described_class.new("option", element_class, value) }.not_to raise_error
      end
    end
  end

  describe "#==" do
    context "when comparing two settings" do
      let(:setting_1) { described_class.new("option_1", element_class_1, value_1) }
      let(:element_class_1) { String }
      let(:setting_2) { described_class.new("option_1", element_class_2, value_2) }
      let(:element_class_2) { String }

      context "where one was given a non array value" do
        let(:value_1) { "a string" }
        context "and the other also the same non array value" do
          let(:value_2) { "a string" }
          it "should be equal" do
            expect(setting_1).to be == setting_2
          end
        end
        context "and the other also the same value in an array" do
          let(:value_2) { [ "a string" ] }
          it "should be equal" do
            expect(setting_1).to be == setting_2
          end
        end
        context "and the other a different non array value" do
          let(:value_2) { "a different string" }
          it "should be equal" do
            expect(setting_1).to_not be == setting_2
          end
        end
        context "and the other a different value in an array" do
          let(:value_2) { [ "a different string" ] }
          it "should be equal" do
            expect(setting_1).to_not be == setting_2
          end
        end
      end

      context "where one was given a value in an array" do
        let(:value_1) { [ "a string"] }
        context "and the other the same value in an array" do
          let(:value_2) { [ "a string" ] }
          it "should be equal" do
            expect(setting_1).to be == setting_2
          end
        end
        context "and the other the same value not in an array" do
          let(:value_2) { "a string" }
          it "should be equal" do
            expect(setting_1).to be == setting_2
          end
        end
        context "and the other a different value in an array" do
          let(:value_2) { [ "a different string" ] }
          it "should be equal" do
            expect(setting_1).to_not be == setting_2
          end
        end
        context "and the other a different value in an array" do
          let(:value_2) { "a different string" }
          it "should be equal" do
            expect(setting_1).to_not be == setting_2
          end
        end
      end
    end
  end
end
