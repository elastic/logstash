# encoding: utf-8
require "spec_helper"
require "logstash/settings"
require "tmpdir"
require "socket" # for UNIXSocket

describe LogStash::Setting::WritableDirectory do
  let(:mode_rx) { 0555 }
  # linux is 108, Macos is 104, so use a safe value
  # Stud::Temporary.pathname, will exceed that size without adding anything
  let(:parent) { File.join(Dir.tmpdir, Time.now.to_f.to_s) }
  let(:path) { File.join(parent, "fancy") }

  before { Dir.mkdir(parent) }
  after { Dir.exist?(path) && Dir.unlink(path) rescue nil }
  after { Dir.unlink(parent) }

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
        before { File.chmod(mode_rx, parent) }
        it "should fail" do
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
        before { File.chmod(0, path) }
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

      context "but is a symlink" do
        before { File::symlink("whatever", path) }
        it_behaves_like "failure"
      end
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
          # Remove write permission on the parent
          File.chmod(mode_rx, parent)
        end

        it_behaves_like "failure"
      end
    end
  end
end
