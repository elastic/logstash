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

require 'spec_helper'
require 'logstash/util/java_version'

describe "LogStash::Util::JavaVersion" do
  subject(:mod) { LogStash::Util::JavaVersion }

  it "should get the current java version if we're on Java" do
    expect(LogStash::Util::JavaVersion.version).to be_a(String)
  end

  it "should mark a bad beta version as bad" do
    expect(mod.bad_java_version?("1.7.0_45-beta")).to be_truthy
  end

  it "should mark a bad standard version as bad" do
    expect(mod.bad_java_version?("1.6.0")).to be_truthy
  end

  it "should mark java 7 version as bad" do
    expect(mod.bad_java_version?("1.7.0_51")).to be_truthy
  end

  it "should mark java version 8 as good" do
    expect(mod.bad_java_version?("1.8.0")).to be_falsey
  end

  it "should mark a good standard java version as good" do
    expect(mod.bad_java_version?("1.8.0_65")).to be_falsey
  end

  it "should mark a good beta version as good" do
    expect(mod.bad_java_version?("1.8.0-beta")).to be_falsey
  end

  it "should not mark non-standard javas as bad (IBM JDK)" do
    expect(mod.bad_java_version?("pwi3270sr9fp10-20150708_01 (SR9 FP10)")).to be_falsey
  end

  context ".validate_java_version!" do
    context "with good version" do
      before do
        expect(mod).to receive(:version).and_return("1.8.0")
      end

      it "doesn't raise an error" do
        expect { mod.validate_java_version! }.not_to raise_error
      end
    end

    context "with a bad version" do
      before do
        expect(mod).to receive(:version).and_return("1.7.0").twice
      end

      it "raises an error" do
        expect { mod.validate_java_version! }.to raise_error RuntimeError, /Java version 1.8.0 or later/
      end
    end
  end

  describe "parsing java versions" do
    it "should return nil on a nil version" do
      expect(mod.parse_java_version(nil)).to be_nil
    end

    it "should return nil on non-hotspot javas" do
      # Not sure this is what is being returned, but it doesn't match the
      # regex, which is the point
      expect(mod.parse_java_version("JCL - 20140103_01 based on Oracle 7u51-b11
")).to be_nil
    end

    shared_examples("version parsing") do |desc, string, major, minor, patch, update, build|
      context("#{desc} with version #{string}") do
        subject(:parsed) { LogStash::Util::JavaVersion.parse_java_version(string) }

        it "should have the correct major version" do
          expect(parsed[:major]).to eql(major)
        end

        it "should have the correct minor version" do
          expect(parsed[:minor]).to eql(minor)
        end

        it "should have the correct patch version" do
          expect(parsed[:patch]).to eql(patch)
        end

        it "should have the correct update version" do
          expect(parsed[:update]).to eql(update)
        end

        it "should have the correct build string" do
          expect(parsed[:build]).to eql(build)
        end
      end
    end

    include_examples("version parsing", "a plain version", "1.3.0", 1, 3, 0, 0, nil)
    include_examples("version parsing", "an update", "1.4.0_03", 1, 4, 0, 3, nil)
    include_examples("version parsing", "a build", "1.4.0-beta", 1, 4, 0, 0, "beta")
    include_examples("version parsing", "an update+build", "1.4.0_03-beta", 1, 4, 0, 3, "beta")
  end
end
