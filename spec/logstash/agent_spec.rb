require 'spec_helper'

describe LogStash::Agent do
  subject { LogStash::Agent.new('') }
  let(:dummy_config) { 'input {}' }

  context "when loading the configuration" do
    context "when local" do
      before { expect(subject).to receive(:local_config).with(path) }

      context "unix" do
        let(:path) { './test.conf' }
        it 'works with relative path' do
          subject.load_config(path)
        end
      end

      context "windows" do
        let(:path) { '.\test.conf' }
        it 'work with relative windows path' do
          subject.load_config(path)
        end
      end
    end
    
    context "when remote" do
      context 'supported scheme' do
        let(:path) { "http://test.local/superconfig.conf" }

        before { expect(Net::HTTP).to receive(:get) { dummy_config } }
        it 'works with http' do
          expect(subject.load_config(path)).to eq("#{dummy_config}\n")
        end
      end
    end
  end
end
