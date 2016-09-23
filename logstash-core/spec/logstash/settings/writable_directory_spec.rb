# encoding: utf-8
require "spec_helper"
require "logstash/settings"
require "stud/temporary"
require "socket" # for UNIXSocket

describe LogStash::Setting::WritableDirectory do
  let(:path) { Stud::Temporary.pathname }

  shared_examples "failure" do
    it "should fail" do
      expect { subject.set(path) }.to raise_error
    end
  end

  subject do
    # Create a new WritableDirectory setting with no default value strict
    # disabled.
    described_class.new("fancy.path", "", false)
  end

  describe "#set" do
    context "when the directory exists" do
      before { Dir.mkdir(path) }
      after { Dir.unlink(path) }

      context "and is writable" do
        # assume this spec already created a directory that's writable... fair? :)
        it "should return true" do
          expect(subject.set(path)).to be_truthy
        end
      end

      context "but is not writable" do
        before do
          File.chmod(0, path)
        end

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
      end
      context "but is a symlink not pointing to a directory" do
        before { File::symlink("some nonexisting location", path) }
        it_behaves_like "failure"
      end
    end

    context "when the directory is missing" do
      # Create a path with at least one subdirectory we can try to fiddle with permissions
      let(:parent) { Stud::Temporary.pathname }
      let(:path) { File.join(parent, "fancy") }
      before { Dir.mkdir(parent) }
      after { Dir.unlink(parent) }

      context "but can be created" do
        before do
          # If the path doesn't exist, we want to try creating it, so let's be
          # extra careful and make sure the path doesn't exist yet.
          expect(File.directory?(path)).to be_falsey
        end

        after { Dir.unlink(path) }

        it "should return true" do
          expect(subject.set(path)).to be_truthy
        end
      end

      context "and cannot be created" do
        before do
          # Remove write permission on the parent
          File.chmod(0555, parent)
        end

        it_behaves_like "failure"
      end
    end
  end
end
