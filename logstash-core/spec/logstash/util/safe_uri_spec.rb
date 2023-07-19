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

require "logstash/util/safe_uri"
require "spec_helper"

module LogStash module Util
  describe SafeURI do
    describe "#clone" do
      subject { LogStash::Util::SafeURI.new("http://localhost:9200/uri?q=s") }
      it "allows modifying uri parameters" do
        cloned_safe_uri = subject.clone
        cloned_safe_uri.path = "/cloned"
        cloned_safe_uri.query = "a=b"
        expect(subject.path).to eq("/uri")
        expect(subject.query).to eq("q=s")
        expect(cloned_safe_uri.path).to eq("/cloned")
        expect(cloned_safe_uri.query).to eq("a=b")
      end
    end

    describe "equality" do
      subject { LogStash::Util::SafeURI.new("https://localhost:9200/uri") }

      it "should eql/== to dup" do
        expect(subject == subject.clone).to be true
        expect(subject == subject.dup).to be true
        expect(subject.eql? subject.dup).to be true
      end

      it "should eql to same uri" do
        uri = LogStash::Util::SafeURI.new("https://localhost:9200/uri")
        expect(uri.eql? subject).to be true
        expect(subject.hash).to eql uri.hash
      end
    end

    describe "handling escapable fields" do
      let(:user) { "u%20" }
      let(:password) { "p%20ss" }
      let(:path) { "/a%20/path" }
      let(:query) { "a%20query&another=es%3dq" }
      let(:fragment) { "spacey%20fragment" }
      subject { LogStash::Util::SafeURI.new("http://#{user}:#{password}@example.net#{path}?#{query}\##{fragment}") }

      [:user, :password, :path, :query, :fragment].each do |field|
        it "should not escape the #{field} field" do
          expected = self.send(field)
          expect(subject.send(field)).to eq(expected)
        end
      end
    end

    describe "#initialize" do
      context 'when host is required' do
        MALFORMED_URIS = ['http:/user:pass@localhost:9600', 'http:/localhost', 'http:/localhost:9600', 'h;localhost', 'http:://localhost']

        context 'malformed uris via string' do
          MALFORMED_URIS.each do |arg|
            it "#{arg}: should raise an error" do
              expect {LogStash::Util::SafeURI.new(arg)}.to raise_error(ArgumentError)
            end
          end
        end

        context 'malformed uris via java.net.URI' do
          MALFORMED_URIS.each do |arg|
            it "#{arg}: should raise an error" do
              java_uri = java.net.URI.new(arg)
              expect {LogStash::Util::SafeURI.new(java_uri)}.to raise_error(ArgumentError)
            end
          end
        end

        context 'malformed uris via Ruby URI' do
          MALFORMED_URIS.each do |arg|
            it "#{arg}: should raise an error" do
              ruby_uri = URI.parse(arg)
              expect {LogStash::Util::SafeURI.new(ruby_uri)}.to raise_error(ArgumentError)
            end
          end
        end

        context 'uris with a valid host' do
          ['http://user:pass@notlocalhost:9600', 'http://notlocalhost', 'https://notlocalhost:9600', '//notlocalhost', 'notlocalhost', 'notlocalhost:9200'].each do |arg|
            it "#{arg}: should resolve host correctly" do
              expect(LogStash::Util::SafeURI.new(arg).host).to eq('notlocalhost')
            end
          end
        end
      end
    end

    describe "normalization" do
      subject { LogStash::Util::SafeURI.new("HTTPS://FOO:BaR@S11.ORG") }

      it "should normalize" do # like URI().normalize
        subject.normalize!
        expect(subject.to_s).to eq('https://FOO:xxxxxx@s11.org/')
      end
    end

    describe "writers" do
      subject { LogStash::Util::SafeURI.new("http://sample.net") }

      it "should update :user" do
        subject.user = 'user'
        expect(subject.user).to eq('user')
        expect(subject.to_s).to eq('http://user@sample.net/')
      end

      it "should update :password" do
        subject.user = 'user'
        subject.password = 'pass'
        expect(subject.password).to eq('pass')
      end

      it "should update :path" do
        subject.path = '/path'
        expect(subject.path).to eq('/path')
        expect(subject.to_s).to eq('http://sample.net/path')

        subject.path = ''
        expect(subject.path).to eq('/')
        expect(subject.to_s).to eq('http://sample.net/')
      end

      it "should update :host" do
        subject.host = '127.0.0.1'
        expect(subject.host).to eq('127.0.0.1')
        expect(subject.to_s).to eq('http://127.0.0.1/')
      end

      it "should update :scheme" do
        subject.update(:scheme, 'https')
        expect(subject.scheme).to eq('https')
        expect(subject.to_s).to eq('https://sample.net/')
      end
    end
  end
end end
