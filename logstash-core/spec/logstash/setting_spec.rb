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
require "logstash/settings"

describe LogStash::Setting do
  let(:logger) { double("logger") }
  describe "#value" do
    context "when using a default value" do
      context "when no value is set" do
        subject { described_class.new("number", Numeric, 1) }
        it "should return the default value" do
          expect(subject.value).to eq(1)
        end
      end

      context "when a value is set" do
        subject { described_class.new("number", Numeric, 1) }
        let(:new_value) { 2 }
        before :each do
          subject.set(new_value)
        end
        it "should return the set value" do
          expect(subject.value).to eq(new_value)
        end
      end
    end

    context "when not using a default value" do
      context "when no value is set" do
        subject { described_class.new("number", Numeric, nil, false) }
        it "should return the default value" do
          expect(subject.value).to eq(nil)
        end
      end

      context "when a value is set" do
        subject { described_class.new("number", Numeric, nil, false) }
        let(:new_value) { 2 }
        before :each do
          subject.set(new_value)
        end
        it "should return the set value" do
          expect(subject.value).to eq(new_value)
        end
      end
    end
  end

  describe "#set?" do
    context "when there is not value set" do
      subject { described_class.new("number", Numeric, 1) }
      it "should return false" do
        expect(subject.set?).to be(false)
      end
    end
    context "when there is a value set" do
      subject { described_class.new("number", Numeric, 1) }
      before :each do
        subject.set(2)
      end
      it "should return false" do
        expect(subject.set?).to be(true)
      end
    end
  end

  describe "#set" do
    subject { described_class.new("number", Numeric, 1) }
    it "should change the value of a setting" do
      expect(subject.value).to eq(1)
      subject.set(4)
      expect(subject.value).to eq(4)
    end
    context "when executed for the first time" do
      it "should change the result of set?" do
        expect(subject.set?).to eq(false)
        subject.set(4)
        expect(subject.set?).to eq(true)
      end
    end
    context "when the argument's class does not match @klass" do
      it "should throw an exception" do
        expect { subject.set("not a number") }.to raise_error ArgumentError
      end
    end
    context "when strict=false" do
      let(:strict) { false }
      subject { described_class.new("number", Numeric, 1, strict) }
      before do
        expect(subject).not_to receive(:validate)
      end

      it "should not call #validate" do
        subject.set(123)
      end
    end
    context "when strict=true" do
      let(:strict) { true }
      subject { described_class.new("number", Numeric, 1, strict) }
      before do
        expect(subject).to receive(:validate)
      end

      it "should call #validate" do
        subject.set(123)
      end
    end
  end

  describe "#reset" do
    subject { described_class.new("number", Numeric, 1) }
    context "if value is already set" do
      before :each do
        subject.set(2)
      end
      it "should reset value to default" do
        subject.reset
        expect(subject.value).to eq(1)
      end
      it "should reset set? to false" do
        expect(subject.set?).to eq(true)
        subject.reset
        expect(subject.set?).to eq(false)
      end
    end
  end

  describe "validator_proc" do
    let(:default_value) { "small text" }
    subject { described_class.new("mytext", String, default_value) {|v| v.size < 20 } }
    context "when validation fails" do
      let(:new_value) { "very very very very very big text" }
      it "should raise an exception" do
        expect { subject.set(new_value) }.to raise_error ArgumentError
      end
      it "should not change the value" do
        subject.set(new_value) rescue nil
        expect(subject.value).to eq(default_value)
      end
    end
    context "when validation is successful" do
      let(:new_value) { "smaller text" }
      it "should not raise an exception" do
        expect { subject.set(new_value) }.to_not raise_error
      end
      it "should change the value" do
        subject.set(new_value)
        expect(subject.value).to eq(new_value)
      end
    end
  end
end
