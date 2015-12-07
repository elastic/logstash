# encoding: utf-8
require 'spec_helper'



describe LogStash::OutputDelegator do
  let(:logger) { double("logger") }
  let(:out_klass) { double("output klass") }
  let(:out_inst) { double("output instance") }

  subject { described_class.new(logger, out_klass) }

  before do
    allow(out_klass).to receive(:new).with(any_args).and_return(out_inst)
    allow(out_inst).to receive(:register)
  end

  it "should initialize cleanly" do
    subject
  end
end
