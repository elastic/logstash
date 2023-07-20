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
require 'ostruct'
require "bootstrap/util/compress"
require "stud/temporary"
require "fileutils"

def build_zip_file(structure)
  source = Stud::Temporary.pathname
  FileUtils.mkdir_p(source)

  structure.each do |p|
    file = ::File.basename(p)
    path = ::File.join(source, ::File.dirname(p))
    full_path = ::File.join(path, file)

    FileUtils.mkdir_p(path)
    ::File.open(full_path, "a") do |f|
      f.write("Hello - #{Time.now.to_i.to_s}")
    end
  end

  target = Stud::Temporary.pathname
  FileUtils.mkdir_p(target)
  target_file = ::File.join(target, "mystructure.zip")

  LogStash::Util::Zip.compress(source, target_file)
  target_file
rescue => e
  FileUtils.rm_rf(target) if target
  raise e
ensure
  FileUtils.rm_rf(source)
end

def list_files(target)
  Dir.glob(::File.join(target, "**", "*")).select { |f| ::File.file?(f) }.size
end

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
      ["foo", "bar", "zoo"].inject([]) do |acc, name|
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

    context "patterns" do
      # Theses tests sound duplicated but they are actually better than the other one
      # since they do not involve any mocks.
      subject { described_class }

      let(:zip_structure) {
        [
          "logstash/logstash-output-secret/logstash-output-monitoring.gem",
          "logstash/logs/more/log.log",
          "kibana/package.json",
          "elasticsearch/jars.jar",
          "elasticsearch/README.md"
        ]
      }

      let(:zip_file) { build_zip_file(zip_structure) }
      let(:target) { Stud::Temporary.pathname }

      context "when no matching pattern is supplied" do
        it "extracts all the file" do
          subject.extract(zip_file, target)

          expect(list_files(target)).to eq(zip_structure.size)

          zip_structure.each do |full_path|
            expect(::File.exist?(::File.join(target, full_path))).to be_truthy
          end
        end
      end

      context "when a matching pattern is supplied" do
        it "extracts only the relevant files" do
          subject.extract(zip_file, target, /logstash\/?/)

          expect(list_files(target)).to eq(2)

          ["logstash/logstash-output-secret/logstash-output-monitoring.gem",
           "logstash/logs/more/log.log"].each do |full_path|
            expect(::File.exist?(::File.join(target, full_path))).to be_truthy
          end
        end
      end
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
      ["foo", "bar", "zoo"]
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
      ["foo", "bar", "zoo"].inject([]) do |acc, name|
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
      ["foo", "bar", "zoo"]
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
