# encoding: utf-8
require "spec_helper"
require "logstash/util/buftok"

describe  FileWatch::BufferedTokenizer  do

  context "test" do

    it "should tokenize a single token" do
      t = FileWatch::BufferedTokenizer.new
      expect(t.extract("foo\n")).to eq(["foo"])
    end

    it "should merge multiple token" do
      t = FileWatch::BufferedTokenizer.new
      expect(t.extract("foo")).to eq([])
      expect(t.extract("bar\n")).to eq(["foobar"])
    end

    it "should tokenize multiple token" do
      t = FileWatch::BufferedTokenizer.new
      expect(t.extract("foo\nbar\n")).to eq(["foo", "bar"])
    end

    it "should ignore empty payload" do
      t = FileWatch::BufferedTokenizer.new
      expect(t.extract("")).to eq([])
      expect(t.extract("foo\nbar")).to eq(["foo"])
    end

    it "should tokenize empty payload with newline" do
      t = FileWatch::BufferedTokenizer.new
      expect(t.extract("\n")).to eq([""])
      expect(t.extract("\n\n\n")).to eq(["", "", ""])
    end

  end
end
