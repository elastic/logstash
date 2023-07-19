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
require "logstash/util/charset"

describe LogStash::Util::Charset do
  let(:logger) { double("logger") }

  context "with valid UTF-8 source encoding" do
    subject {LogStash::Util::Charset.new("UTF-8")}

    it "should return untouched data" do
      ["foobar", "κόσμε"].each do |data|
        expect(data.encoding.name).to eq("UTF-8")
        expect(subject.convert(data)).to eq(data)
        expect(subject.convert(data).encoding.name).to eq("UTF-8")
      end
    end
  end

  context "with invalid UTF-8 source encoding" do
    subject do
      LogStash::Util::Charset.new("UTF-8").tap do |charset|
        charset.logger = logger
      end
    end

    it "should escape invalid sequences" do
      ["foo \xED\xB9\x81\xC3", "bar \xAD"].each do |data|
        expect(data.encoding.name).to eq("UTF-8")
        expect(data.valid_encoding?).to eq(false)
        expect(logger).to receive(:warn).exactly(2).times
        #logger.should_receive(:warn).twice
        expect(subject.convert(data)).to eq(data.inspect[1..-2])
        expect(subject.convert(data).encoding.name).to eq("UTF-8")
      end
    end
  end

  context "with valid non UTF-8 source encoding" do
    subject {LogStash::Util::Charset.new("ISO-8859-1")}

    it "should encode to UTF-8" do
      samples = [
        ["foobar", "foobar"],
        ["\xE0 Montr\xE9al", "à Montréal"],
      ]
      samples.map {|(a, b)| [a.force_encoding("ISO-8859-1"), b]}.each do |(a, b)|
        expect(a.encoding.name).to eq("ISO-8859-1")
        expect(b.encoding.name).to eq("UTF-8")
        expect(a.valid_encoding?).to eq(true)
        expect(subject.convert(a).encoding.name).to eq("UTF-8")
        expect(subject.convert(a)).to eq(b)
      end
    end
  end

  context "with invalid non UTF-8 source encoding" do
    subject {LogStash::Util::Charset.new("ASCII-8BIT")}

    it "should encode to UTF-8 and replace invalid chars" do
      samples = [
        ["\xE0 Montr\xE9al", "� Montr�al"],
        ["\xCE\xBA\xCF\x8C\xCF\x83\xCE\xBC\xCE\xB5", "����������"],
      ]
      samples.map {|(a, b)| [a.force_encoding("ASCII-8BIT"), b]}.each do |(a, b)|
        expect(a.encoding.name).to eq("ASCII-8BIT")
        expect(b.encoding.name).to eq("UTF-8")
        expect(subject.convert(a).encoding.name).to eq("UTF-8")
        expect(subject.convert(a)).to eq(b)
      end
    end
  end
end
