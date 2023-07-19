# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

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
      versions = subject.supported_logstash(gemspec)
      expect { versions.size }.not_to change { versions.uniq }
    end
  end
end
