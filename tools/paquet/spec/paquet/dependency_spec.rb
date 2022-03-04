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
