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

  it "should tokenize a single token" do
    expect(subject.extract("foo\n")).to eq(["foo"])
  end

  it "should merge multiple token" do
    expect(subject.extract("foo")).to eq([])
    expect(subject.extract("bar\n")).to eq(["foobar"])
  end

  it "should tokenize multiple token" do
    expect(subject.extract("foo\nbar\n")).to eq(["foo", "bar"])
  end

  it "should ignore empty payload" do
    expect(subject.extract("")).to eq([])
    expect(subject.extract("foo\nbar")).to eq(["foo"])
  end

  it "should tokenize empty payload with newline" do
    expect(subject.extract("\n")).to eq([""])
    expect(subject.extract("\n\n\n")).to eq(["", "", ""])
  end

  context 'with delimiter' do
    subject { FileWatch::BufferedTokenizer.new(delimiter) }

    let(:delimiter) { "||" }

    it "should tokenize multiple token" do
      expect(subject.extract("foo||b|r||")).to eq(["foo", "b|r"])
    end

    it "should ignore empty payload" do
      expect(subject.extract("")).to eq([])
      expect(subject.extract("foo||bar")).to eq(["foo"])
    end
  end
end
