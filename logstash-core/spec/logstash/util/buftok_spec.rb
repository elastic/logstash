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

describe  FileWatch::BufferedTokenizer  do
  subject { FileWatch::BufferedTokenizer.new }


  # A matcher that ensures the result of BufferedTokenizer#extract "quacks like" an expected ruby Array in two respects:
  #  - #empty? -> boolean: true indicates that the _next_ Enumerable#each will emit zero items.
  #  - #entries -> Array: the ordered entries
  def emit_exactly(expected_array)
    # note: order matters; Iterator#each and the methods that delegate to it consume the iterator
    have_attributes(:empty? => expected_array.empty?,
                    :entries => expected_array.entries) # consumes iterator, must be done last
  end

  it "should tokenize a single token" do
    expect(subject.extract("foo\n")).to emit_exactly(["foo"])
  end

  it "should merge multiple token" do
    expect(subject.extract("foo")).to emit_exactly([])
    expect(subject.extract("bar\n")).to emit_exactly(["foobar"])
  end

  it "should tokenize multiple token" do
    expect(subject.extract("foo\nbar\n")).to emit_exactly(["foo", "bar"])
  end

  it "should ignore empty payload" do
    expect(subject.extract("")).to emit_exactly([])
    expect(subject.extract("foo\nbar")).to emit_exactly(["foo"])
  end

  it "should tokenize empty payload with newline" do
    expect(subject.extract("\n")).to emit_exactly([""])
    expect(subject.extract("\n\n\n")).to emit_exactly(["", "", ""])
  end

  describe 'flush' do
    let(:data) { "content without a delimiter" }
    before(:each) do
      subject.extract(data)
    end

    it "emits the contents of the buffer" do
      expect(subject.flush).to eq(data)
    end

    it "resets the state of the buffer" do
      subject.flush
      expect(subject).to be_empty
    end

    context 'with decode_size_limit_bytes' do
      subject { FileWatch::BufferedTokenizer.new("\n", 100) }

      it "validates size limit" do
        expect { FileWatch::BufferedTokenizer.new("\n", -101) }.to raise_error(java.lang.IllegalArgumentException, "Size limit must be positive")
        expect { FileWatch::BufferedTokenizer.new("\n", 0) }.to raise_error(java.lang.IllegalArgumentException, "Size limit must be positive")
      end

      it "emits the contents of the buffer" do
        expect(subject.flush).to eq(data)
      end

      it "resets the state of the buffer" do
        subject.flush
        expect(subject).to be_empty
      end
    end
  end

  context 'with delimiter' do
    subject { FileWatch::BufferedTokenizer.new(delimiter) }

    let(:delimiter) { "||" }

    it "should tokenize multiple token" do
      expect(subject.extract("foo||b|r||")).to emit_exactly(["foo", "b|r"])
    end

    it "should ignore empty payload" do
      expect(subject.extract("")).to emit_exactly([])
      expect(subject.extract("foo||bar")).to emit_exactly(["foo"])
    end
  end
end
