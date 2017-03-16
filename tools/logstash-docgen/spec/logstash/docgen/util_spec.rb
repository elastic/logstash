# encoding: utf-8
require "logstash/docgen/util"
require "spec_helper"

describe LogStash::Docgen::Util do
  subject { LogStash::Docgen::Util }

  context "time_execution" do
    it "prints the execution time to stdout" do

      output = capture do
        subject.time_execution do
          sleep(0.1)
        end
      end

      expect(output).to match(/Execution took: \d(\.\d+)?s/)
    end

    it "returns the value of the block" do
      value = subject.time_execution do
        1 + 2
      end

      expect(value).to eq(3)
    end
  end

  it "returns a red string" do
    expect(subject.red("Hello")).to eq("\e[31mHello\e[0m")
  end

  it "returns a green string" do
    expect(subject.green("Hello")).to eq("\e[32mHello\e[0m")
  end

  it "returns a yellow string" do
    expect(subject.yellow("Hello")).to eq("\e[33mHello\e[0m")
  end
end
