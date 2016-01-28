# encoding: utf-8
require "spec_helper"
require "bootstrap/environment"

describe LogStash::Environment do
  describe "format_argv" do
    context "when passing just irb/pry" do
      before(:each) do
        allow(subject).to receive(:puts)
      end
      ["pry", "irb"].each do |console|
        it "transforms [\"#{console}\"] to --interactive switches" do
          expect(subject.format_argv([console])).to eq(["--interactive", console])
        end
      end
    end

    context "when passing cli arguments" do
      let(:argv) { ["--pipeline.workers", 4] }
      let(:yml_settings) { ["--pipeline.workers", 2] }

      before(:each) do
        allow(subject).to receive(:fetch_yml_settings).and_return(yml_settings)
      end

      it "should place settings from yaml before settings from cli" do
        expect(subject.format_argv(argv)).to eq(yml_settings + argv)
      end
    end
  end
end
