# encoding: utf-8
require "paquet/gem"
require "stud/temporary"

describe Paquet::Gem do
  let(:target_path) { Stud::Temporary.pathname }
  let(:dummy_gem) { "dummy-gem" }

  subject { described_class.new(target_path) }

  it "adds gem to pack" do
    subject.add(dummy_gem)
    expect(subject.gems).to include(dummy_gem)
  end

  it "allows to ignore gems" do
    subject.ignore(dummy_gem)
    expect(subject.ignore?(dummy_gem))
  end

  it "keeps track of the number of gem to pack" do
    expect { subject.add(dummy_gem) }.to change { subject.size }.by(1)
  end
end
