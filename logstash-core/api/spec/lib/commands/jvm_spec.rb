# encoding: utf-8
require_relative "../../spec_helper"
require "app/stats/hotthreads_command"
require 'ostruct'

describe LogStash::Api::HotThreadsCommand do


  context "#schema" do
    let(:report) { subject.run }

    it "return hot threads information" do
      expect(report).not_to be_empty
    end

  end
end
