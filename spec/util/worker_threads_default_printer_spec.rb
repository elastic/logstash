# encoding: utf-8
require "spec_helper"
require "logstash/util/worker_threads_default_printer"

describe LogStash::Util::WorkerThreadsDefaultPrinter do
  let(:settings) { {} }
  let(:collector) { [] }

  subject { described_class.new(settings) }

  context 'when the settings hash is empty' do
    it 'the #visit method returns a string with 1 filter worker' do
      subject.visit(collector)
      expect(collector.first).to eq("Filter workers: 1")
    end
  end

  context 'when the settings hash has content' do
    let(:settings) { {'filter-workers' => 42} }

    it 'the #visit method returns a string with 42 filter workers' do
      subject.visit(collector)
      expect(collector.first).to eq("Filter workers: 42")
    end
  end
end
