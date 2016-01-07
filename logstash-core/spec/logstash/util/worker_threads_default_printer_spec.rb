# encoding: utf-8
require "spec_helper"
require "logstash/util/worker_threads_default_printer"

describe LogStash::Util::WorkerThreadsDefaultPrinter do
  let(:settings)  { {} }
  let(:collector) { [] }

  subject { described_class.new(settings) }

  before { subject.visit(collector) }

  describe "the #visit method" do
    context 'when the settings hash is empty' do
      it 'adds nothing to the collector' do
        subject.visit(collector)
        expect(collector).to eq([])
      end
    end

    context 'when the settings hash has both user and default content' do
      let(:settings) { {:pipeline_workers => 42, :default_pipeline_workers => 5} }

      it 'adds two strings' do
        expect(collector).to eq(["User set pipeline workers: 42", "Default pipeline workers: 5"])
      end
    end

    context 'when the settings hash has only user content' do
      let(:settings) { {:pipeline_workers => 42} }

      it 'adds a string with user set pipeline workers' do
        expect(collector.first).to eq("User set pipeline workers: 42")
      end
    end

    context 'when the settings hash has only default content' do
      let(:settings) { {:default_pipeline_workers => 5} }

      it 'adds a string with default pipeline workers' do
        expect(collector.first).to eq("Default pipeline workers: 5")
      end
    end
  end
end
