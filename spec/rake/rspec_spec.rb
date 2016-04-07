# encoding: utf-8
require "spec_helper"
require "rake/rspec"

describe LogStash::RSpec do

  context "when running with local core gems" do

    let(:specs) { [LogStash::RSpec.core_specs] }

    before(:each) do
      allow(subject).to  receive(:run)
      allow(LogStash::BundlerHelpers).to receive(:update)
    end

    it "should cache gemfiles" do
      expect(subject).to receive(:cache_gemfiles).and_call_original
      subject.run_with_local_core_gems(specs)
    end

    it "shuold point the Gemfile to local path" do
      expect(subject).to receive(:point_to_local_core_gems).and_call_original
      subject.run_with_local_core_gems(specs)
    end

    it "should restore the gemfile at the end of the process" do
      expect(subject).to receive(:restore_gemfiles).and_call_original
      subject.run_with_local_core_gems(specs)
    end
  end
end

describe GemfileHelpers do

  let(:core_gems_list) do
    [ "logstash-core", "logstash-core-event-java", "logstash-core-plugin-api" ]
  end

  let(:gem_wrapper_double) { double("gem-wrapper") }
  let(:gemfile)            { double("gemfile") }
  let(:gemset)             { double("gemset") }

  it "should find all core gems" do
    expect(subject.find_core_gems).to eq(core_gems_list)
  end

  describe "Gemfile manipulation" do

    it "should point core gems to local path" do
      core_gems_list.each do |core_gem_name|
        expect(subject).to receive(:update_gem).with(any_args, core_gem_name, {:path => "./#{core_gem_name}" })
      end
      subject.point_to_local_core_gems
    end

    it "should point core released gems" do
      core_gems_list.each do |core_gem_name|
        expect(subject).to receive(:update_gem).with(any_args, core_gem_name, {})
      end
      subject.point_to_released_core_gems
    end
  end
end
