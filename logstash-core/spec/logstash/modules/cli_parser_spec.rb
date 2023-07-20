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
require "logstash/modules/cli_parser"

describe LogStash::Modules::CLIParser do
  subject { LogStash::Modules::CLIParser.new(module_names, module_variables) }
  let(:logger) { double("logger") }
  let(:module_name) { "foo" }
  let(:module_names) { [module_name, "bar"] }
  let(:proto_key_value) { "var.input.stdin.type=example" }
  let(:proto_mod_vars) { module_name + "." + proto_key_value }
  let(:module_variables) { [proto_mod_vars] }
  let(:expected_output) { { "name" => module_name, "var.input.stdin.type" => "example" } }

  describe ".parse_modules" do
    let(:module1) { "module1" }
    let(:module2) { "module2" }
    let(:csv_modules) { "#{module1},#{module2}" }
    let(:list_with_csv) { [module_name, csv_modules] }
    let(:post_parse) { [module_name, module1, module2] }

    context "when it receives an array without a csv entry" do
      it "return the array unaltered" do
        expect(subject.parse_modules(module_names)).to eq(module_names)
      end
    end

    context "when it receives an empty array" do
      it "return an empty array" do
        expect(subject.parse_modules([])).to eq([])
      end
    end

    context "when it receives an array with a csv entry" do
      it "return the original array with the csv values split into elements" do
        expect(subject.parse_modules(list_with_csv)).to eq(post_parse)
      end
    end

    context "when it receives an array with a bad csv entry" do
      let(:bad_modules) { ["-Minvalid", module1] }
      it "raise a LogStash::ConfigLoadingError exception" do
        expect { subject.parse_modules(bad_modules) }.to raise_error LogStash::ConfigLoadingError
      end
    end

    context "when it receives a nil value in an array" do
      let(:array_with_nil) { list_with_csv << nil }
      it "skip it" do
        expect(subject.parse_modules(array_with_nil)).to eq(post_parse)
      end
    end
  end

  describe ".get_kv" do
    context "when it receives a valid string" do
      let(:expected_key) { "var.input.stdin.type" }
      let(:expected_value) { "example" }
      let(:unparsed) { expected_key + "=" + expected_value }
      it "split it into a key value pair" do
        expect(subject.get_kv(module_name, unparsed)).to eq([expected_key, expected_value])
      end
    end

    context "when it receives an invalid string" do
      let(:bad_example) { "var.fail" }
      it "raise a LogStash::ConfigLoadingError exception" do
        expect { subject.get_kv(module_name, bad_example) }.to raise_error LogStash::ConfigLoadingError
      end
    end
  end

  describe ".name_splitter" do
    context "when it receives a valid string" do
      let(:expected) { "var.input.stdin.type=example" }
      it "split the module name from the rest of the string" do
        expect(subject.name_splitter(proto_mod_vars)).to eq([module_name, expected])
      end
    end

    context "when it receives an invalid string" do
      let(:bad_example) { "var.fail" }
      it "raise a LogStash::ConfigLoadingError exception" do
        expect { subject.name_splitter(bad_example) }.to raise_error LogStash::ConfigLoadingError
      end
    end
  end

  describe ".parse_vars" do
    context "when it receives a vars_list with valid strings" do
      it "return a hash with the module name and associated variables as key value pairs" do
        expect(subject.parse_vars(module_name, module_variables)).to eq(expected_output)
      end
    end

    context "when it receives a string that doesn't start with module_name" do
      let(:has_unrelated) { module_variables << "bar.var.input.stdin.type=different" }
      it "skips it" do
        expect(subject.parse_vars(module_name, has_unrelated)).to eq(expected_output)
      end
    end

    context "when it receives an empty vars_list" do
      let(:name_only) { { "name" => module_name } }
      it "return a hash with only 'name => module_name'" do
        expect(subject.parse_vars(module_name, [])).to eq(name_only)
      end
    end
  end

  describe ".parse_it" do
    context "when it receives a valid module_list and module_variable_list" do
      let(:module_names) { [module_name]}
      it "@output is array of hashes with the module name and associated variables as key value pairs" do
        expect(subject.output).to eq([expected_output])
      end
    end

    context "when it receives a non-array value for module_list" do
      let(:module_names) { "string value" }
      it "return an empty array" do
        expect(subject.output).to eq([])
      end
    end
  end
end
