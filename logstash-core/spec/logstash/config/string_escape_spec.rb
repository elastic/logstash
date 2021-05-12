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

require "logstash/config/string_escape"

describe LogStash::Config::StringEscape do

  let(:string_escape) { fail NotImplementedError } # specify which
  let(:result) { string_escape.process_escapes(text) }

  table = {
    '\\"' => '"',
    "\\'" => "'",
    "\\n" => "\n",
    "\\r" => "\r",
    "\\t" => "\t",
    "\\\\"=> "\\",
    "\\0" => "\x00", # null-byte (since 8.0)
    "🙂"   => "🙂",  # multibyte characters pass through
    "\\"  => "\\", # legacy: emit trailing unescaped backslash
    "\\g" => "g",  # legacy: absorb meaningless backslashes
    "\\🙂" => "🙂", # legacy: absorb meaningless backslashes
  }

  context 'in disabled mode' do
    subject(:string_escape) { described_class::DISABLED }

    table.keys.each do |input|
      context "when processing escaped sequence #{input.inspect}" do
        let(:text) { input }
        it "should produce #{input.inspect} unmodified" do
          expect(result).to be == input
        end
      end
    end
  end

  shared_examples_for 'minimal_mode' do
    table.each do |input, expected|
      context "when processing escaped sequence #{input.inspect}" do
        let(:text) { input }
        it "should produce #{expected.inspect}" do
          expect(result).to be == expected
        end
      end
    end
  end

  context 'in minimal mode' do
    subject(:string_escape) { described_class::MINIMAL }
    include_examples 'minimal_mode'
  end

  context 'using deprecated `StringEscape::process_escapes` class method' do
    let(:string_escape) { described_class }
    let(:deprecation_logger_stub) { double('DeprecationLogger').as_null_object }
    before(:each) do
      allow(described_class).to receive(:deprecation_logger).and_return(deprecation_logger_stub)
    end

    it 'emits a deprecation log for each callsite' do
      10.times do
        string_escape::process_escapes("\\0\nmmhmm")
        string_escape::process_escapes("\t\rokay")
      end
      expect(deprecation_logger_stub).to have_received(:deprecated).with(/process_escapes/).twice
    end

    it_behaves_like 'minimal_mode'
  end
end
