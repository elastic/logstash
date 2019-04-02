# encoding: utf-8
require 'spec_helper'
require 'logstash/settings'

describe LogStash::Setting::DeprecatedAndRenamed do
  subject(:setting) { described_class.new("option.deprecated", "option.current") }
  let(:value) { Object.new }

  describe '#set' do
    it 'fails with deprecation runtime error and helpful guidance' do
      expect { setting.set(value) }.to raise_exception do |exception|
        expect(exception).to be_a_kind_of(RuntimeError)
        expect(exception.message).to match(/deprecated and removed/)
        expect(exception.message).to include("option.deprecated")
        expect(exception.message).to include("option.current")
      end
    end
  end

  describe '#value' do
    it 'fails with deprecation argument error' do
      expect { setting.value }.to raise_exception do |exception|
        expect(exception).to be_a_kind_of(ArgumentError)
        expect(exception.message).to match(/deprecated and removed/)
        expect(exception.message).to include("option.deprecated")
      end
    end
  end

end