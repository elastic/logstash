# encoding: utf-8
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
              expect{LogStash::Util::SafeURI.new(arg)}.to raise_error(ArgumentError)
            end
          end
        end

        context 'malformed uris via java.net.URI' do
          MALFORMED_URIS.each do |arg|
            it "#{arg}: should raise an error" do
              java_uri = java.net.URI.new(arg)
              expect{LogStash::Util::SafeURI.new(java_uri)}.to raise_error(ArgumentError)
            end
          end
        end

        context 'malformed uris via Ruby URI' do
          MALFORMED_URIS.each do |arg|
            it "#{arg}: should raise an error" do
              ruby_uri = URI.parse(arg)
              expect{LogStash::Util::SafeURI.new(ruby_uri)}.to raise_error(ArgumentError)
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

      context 'when host is not required' do
        MALFORMED_URIS = ['http:/user:pass@localhost:9600', 'http:/localhost', 'http:/localhost:9600', 'h;localhost', 'http:://localhost']

        context 'malformed uris via string' do
          MALFORMED_URIS.each do |arg|
            it "#{arg}: should not raise an error" do
              expect{LogStash::Util::SafeURI.new(arg, false)}.not_to raise_error
            end
          end
        end

        context 'malformed uris via java.net.URI' do
          MALFORMED_URIS.each do |arg|
            it "#{arg}: should not raise an error" do
              java_uri = java.net.URI.new(arg)
              expect{LogStash::Util::SafeURI.new(java_uri, false)}.not_to raise_error
            end
          end
        end

        context 'malformed uris via Ruby URI' do
          MALFORMED_URIS.each do |arg|
            it "#{arg}: should not raise an error" do
              ruby_uri = URI.parse(arg)
              expect{LogStash::Util::SafeURI.new(ruby_uri, false)}.not_to raise_error
            end
          end
        end

        context 'uris with a valid host' do
          ['http://user:pass@notlocalhost:9600', 'http://notlocalhost', 'https://notlocalhost:9600', '//notlocalhost', 'notlocalhost', 'notlocalhost:9200'].each do |arg|
            it "#{arg}: should resolve host correctly" do
              expect(LogStash::Util::SafeURI.new(arg, false).host).to eq('notlocalhost')
            end
          end
        end
      end
    end
  end
end end
