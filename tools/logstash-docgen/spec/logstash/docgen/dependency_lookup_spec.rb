# encoding: utf-8
#
require "logstash/docgen/dependency_lookup"
require "spec_helper"

describe LogStash::Docgen::DependencyLookup do
  let(:gemspec_file) { ::File.join(::File.dirname(__FILE__), "..", "..", "fixtures", "logstash-filter-dummy.gemspec")}
  let(:gemspec) { Gem::Specification.load(gemspec_file) }
  subject { LogStash::Docgen::DependencyLookup }

  it "doesn't include pre-release" do
    VCR.use_cassette("logstash-core") do
      expect(subject.supported_logstash(gemspec)).not_to include(/snapshot|beta|pre/)
    end
  end

  it "includes only top level logstash version" do
    VCR.use_cassette("logstash-core") do
      expect(subject.supported_logstash(gemspec)).to include("5.0.0")
    end
  end

  it "includes any supported versions" do
    VCR.use_cassette("logstash-core") do
      expect(subject.supported_logstash(gemspec)).to include("5.0.0", "2.3.4", "2.3.2")
    end
  end

  it "doesn't include duplicates" do
    VCR.use_cassette("logstash-core") do
      versions =  subject.supported_logstash(gemspec)
      expect { versions.size }.not_to change { versions.uniq }
    end
  end
end
