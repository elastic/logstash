# encoding: utf-8
require "spec_helper"
require "logstash/bundler"

describe LogStash::Bundler do

  context "capture_stdout" do

    it "should capture stdout from block" do
      original_stdout = $stdout
      output, exception = LogStash::Bundler.capture_stdout do
        expect($stdout).not_to eq(original_stdout)
        puts("foobar")
      end
      expect($stdout).to eq(original_stdout)
      expect(output).to eq("foobar\n")
      expect(exception).to eq(nil)
    end

    it "should capture stdout and report exception from block" do
      output, exception = LogStash::Bundler.capture_stdout do
        puts("foobar")
        raise(StandardError, "baz")
      end
      expect(output).to eq("foobar\n")
      expect(exception).to be_a(StandardError)
      expect(exception.message).to eq("baz")
    end
  end
end
