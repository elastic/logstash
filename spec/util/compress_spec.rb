# encoding: utf-8
require "spec_helper"
require 'ostruct'
require "bootstrap/util/compress"

describe LogStash::Util::Zip do

  subject { Class.new { extend LogStash::Util::Zip } }

  context "#extraction" do

    let(:source) { File.join(File.expand_path("."), "source_file.zip") }
    let(:target) { File.expand_path("target_dir") }

    it "raise an exception if the target dir exist" do
      allow(File).to receive(:exist?).with(target).and_return(true)
      expect { subject.extract(source, target) }.to raise_error
    end

    let(:zip_file) do
      [ "foo", "bar", "zoo" ].inject([]) do |acc, name|
        acc << OpenStruct.new(:name => name)
        acc
      end
    end

    it "extract the list of entries from a zip file" do
      allow(Zip::File).to receive(:open).with(source).and_yield(zip_file)
      expect(FileUtils).to receive(:mkdir_p).exactly(3).times
      expect(zip_file).to receive(:extract).exactly(3).times
      subject.extract(source, target)
    end
  end

  context "#compression" do

    let(:target) { File.join(File.expand_path("."), "target_file.zip") }
    let(:source) { File.expand_path("source_dir") }

    it "raise an exception if the target file exist" do
      allow(File).to receive(:exist?).with(target).and_return(true)
      expect { subject.compress(source, target) }.to raise_error
    end

    let(:dir_files) do
      [ "foo", "bar", "zoo" ]
    end

    let(:zip_file) { Class.new }

    it "add a dir to a zip file" do
      allow(Zip::File).to receive(:open).with(target, ::Zip::File::CREATE).and_yield(zip_file)
      allow(Dir).to receive(:glob).and_return(dir_files)
      expect(zip_file).to receive(:add).exactly(3).times
      subject.compress(source, target)
    end
  end
end

describe LogStash::Util::Tar do

  subject { Class.new { extend LogStash::Util::Tar } }

  context "#extraction" do

    let(:source) { File.join(File.expand_path("."), "source_file.tar.gz") }
    let(:target) { File.expand_path("target_dir") }

    it "raise an exception if the target dir exist" do
      allow(File).to receive(:exist?).with(target).and_return(true)
      expect { subject.extract(source, target) }.to raise_error
    end

    let(:gzip_file) { Class.new }

    let(:tar_file) do
      [ "foo", "bar", "zoo" ].inject([]) do |acc, name|
        acc << OpenStruct.new(:full_name => name)
        acc
      end
    end

    it "extract the list of entries from a tar.gz file" do
      allow(Zlib::GzipReader).to receive(:open).with(source).and_yield(gzip_file)
      allow(Gem::Package::TarReader).to receive(:new).with(gzip_file).and_yield(tar_file)

      expect(FileUtils).to receive(:mkdir).with(target)
      expect(File).to receive(:open).exactly(3).times
      subject.extract(source, target)
    end
  end

  context "#compression" do

    let(:target) { File.join(File.expand_path("."), "target_file.tar.gz") }
    let(:source) { File.expand_path("source_dir") }

    it "raise an exception if the target file exist" do
      allow(File).to receive(:exist?).with(target).and_return(true)
      expect { subject.compress(source, target) }.to raise_error
    end

    let(:dir_files) do
      [ "foo", "bar", "zoo" ]
    end

    let(:tar_file) { Class.new }
    let(:tar)      { Class.new }

    it "add a dir to a tgz file" do
      allow(Stud::Temporary).to receive(:file).and_yield(tar_file)
      allow(Gem::Package::TarWriter).to receive(:new).with(tar_file).and_yield(tar)
      allow(Dir).to receive(:glob).and_return(dir_files)
      expect(File).to receive(:stat).exactly(3).times.and_return(OpenStruct.new(:mode => "rw"))
      expect(tar).to receive(:add_file).exactly(3).times
      expect(tar_file).to receive(:rewind)
      expect(subject).to receive(:gzip).with(target, tar_file)
      subject.compress(source, target)
    end
  end
end
