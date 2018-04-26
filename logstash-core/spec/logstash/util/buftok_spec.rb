# encoding: utf-8
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
end
