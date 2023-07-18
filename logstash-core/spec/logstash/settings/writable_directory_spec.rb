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

require "spec_helper"
require "logstash/settings"
require "tmpdir"
require "socket" # for UNIXSocket
require "fileutils"

describe LogStash::Setting::WritableDirectory do
  # linux is 108, Macos is 104, so use a safe value
  # Stud::Temporary.pathname, will exceed that size without adding anything
  let(:parent) { File.join(Dir.tmpdir, Time.now.to_f.to_s) }
  let(:path) { File.join(parent, "fancy") }

  before { Dir.mkdir(parent) }
  after { Dir.exist?(path) && FileUtils.rm_rf(path)}
  after { FileUtils.rm_rf(parent) }

  shared_examples "failure" do
    before { subject.set(path) }
    it "should fail" do
      expect { subject.validate_value }.to raise_error
    end
  end

  subject do
    # Create a new WritableDirectory setting with no default value strict
    # disabled.
    described_class.new("fancy.path", "", false)
  end

  describe "#value" do
    before { subject.set(path) }

    context "when the directory is missing" do
      context "and the parent is writable" do
        after {
          Dir.unlink(path)
        }
        it "creates the directory" do
          subject.value # need to invoke `#value` to make it do the work.
          expect(::File.directory?(path)).to be_truthy
        end
      end

      context "and the directory cannot be created" do
        it "should fail" do
          # using chmod does not work on Windows better mock and_raise("message")
          expect(FileUtils).to receive(:mkdir_p).and_raise("foobar")
          expect { subject.value }.to raise_error
        end
      end
    end
  end

  describe "#set and #validate_value" do
    context "when the directory exists" do
      before { Dir.mkdir(path) }
      after { Dir.unlink(path) }

      context "and is writable" do
        before { subject.set(path) }
        # assume this spec already created a directory that's writable... fair? :)
        it "should return true" do
          expect(subject.validate_value).to be_truthy
        end
      end

      context "but is not writable" do
        # chmod does not work on Windows, mock writable? instead
        before { expect(File).to receive(:writable?).and_return(false) }
        it_behaves_like "failure"
      end
    end

    context "when the path exists" do
      after { File.unlink(path) }

      context "but is a file" do
        before { File.new(path, "w").close }
        it_behaves_like "failure"
      end

      context "but is a socket" do
        let(:socket) { UNIXServer.new(path) }
        before { socket } # realize `socket` value
        after { socket.close }
        it_behaves_like "failure"
      end unless LogStash::Environment.windows?

      context "but is a symlink" do
        before { FileUtils.symlink("whatever", path) }
        it_behaves_like "failure"
      end unless LogStash::Environment.windows?
    end

    context "when the directory is missing" do
      # Create a path with at least one subdirectory we can try to fiddle with permissions

      context "but can be created" do
        before do
          # If the path doesn't exist, we want to try creating it, so let's be
          # extra careful and make sure the path doesn't exist yet.
          expect(File.directory?(path)).to be_falsey
          subject.set(path)
        end

        after do
          Dir.unlink(path)
        end

        it "should return true" do
          expect(subject.validate_value).to be_truthy
        end
      end

      context "and cannot be created" do
        before do
          # chmod does not work on Windows, mock writable? instead
          expect(File).to receive(:writable?).and_return(false)
        end

        it_behaves_like "failure"
      end
    end
  end
end
