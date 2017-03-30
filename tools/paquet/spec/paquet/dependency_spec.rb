# encoding: utf-8
require "paquet/dependency"

describe Paquet::Dependency do
  let(:name) { "mygem" }
  let(:version) { "1.2.3" }
  let(:platform) { "ruby" }

  subject { described_class.new(name, version, platform) }

  it "returns the name" do
    expect(subject.name).to eq(name)
  end

  it "returns the version" do
    expect(subject.version).to eq(version)
  end

  context "when the platform is mri" do
    it "returns true" do
      expect(subject.ruby?).to be_truthy
    end
  end

  context "platform is jruby" do
    let(:platform) { "java"}

    it "returns false" do
      expect(subject.ruby?).to be_falsey
    end
  end

  it "return a meaningful string" do
    expect(subject.to_s).to eq("#{name}-#{version}")
  end
end
