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
require "pluginmanager/main"
require "pluginmanager/prepare_offline_pack"
require "pluginmanager/offline_plugin_packager"
require "stud/temporary"
require "fileutils"
require "webmock"

# This Test only handle the interaction with the OfflinePluginPackager class
# any test for bundler will need to be done as rats test
describe LogStash::PluginManager::PrepareOfflinePack do
  before do
    WebMock.allow_net_connect!
  end

  subject { described_class.new(cmd, {}) }

  let(:temporary_dir) { Stud::Temporary.pathname }
  let(:tmp_zip_file) { ::File.join(temporary_dir, "myspecial.zip") }
  let(:offline_plugin_packager) { double("offline_plugin_packager") }
  let(:cmd_args) { ["--output", tmp_zip_file, "logstash-input-stdin"] }
  let(:cmd) { "prepare-offline-pack" }

  before do
    FileUtils.mkdir_p(temporary_dir)

    allow(LogStash::Bundler).to receive(:invoke!).and_return(nil)
    allow(LogStash::PluginManager::OfflinePluginPackager).to receive(:package).with(anything, anything).and_return(offline_plugin_packager)
  end

  context "when not debugging" do
    before do
      @before_debug_value = ENV["DEBUG"]
      ENV["DEBUG"] = nil
    end

    after do
      ENV["DEBUG"] = @before_debug_value
    end

    it "silences paquet ui reporter" do
      expect(Paquet).to receive(:ui=).with(Paquet::SilentUI)
      subject.run(cmd_args)
    end

    context "when trying to use a core gem" do
      let(:exception) { LogStash::PluginManager::UnpackablePluginError }

      before do
        allow(LogStash::PluginManager::OfflinePluginPackager).to receive(:package).with(anything, anything).and_raise(exception)
      end

      it "catches the error" do
        expect(subject).to receive(:report_exception).with("Offline package", be_kind_of(exception)).and_return(nil)
        subject.run(cmd_args)
      end
    end

    context "when trying to pack a plugin that doesnt exist" do
      let(:exception) { LogStash::PluginManager::PluginNotFoundError }

      before do
        allow(LogStash::PluginManager::OfflinePluginPackager).to receive(:package).with(anything, anything).and_raise(exception)
      end

      it "catches the error" do
        expect(subject).to receive(:report_exception).with("Cannot create the offline archive", be_kind_of(exception)).and_return(nil)
        subject.run(cmd_args)
      end
    end

    context "if the output is directory" do
      let(:tmp_zip_file) { f = Stud::Temporary.pathname; FileUtils.mkdir_p(f); f }
      let(:cmd) { "prepare-offline-pack" }

      before do
        expect(LogStash::PluginManager::OfflinePluginPackager).not_to receive(:package).with(anything)
      end

      after do
        FileUtils.rm_rf(tmp_zip_file)
      end

      it "fails to do any action" do
        expect { subject.run(cmd_args) }.to raise_error Clamp::ExecutionError, /you must specify a filename/
      end
    end

    context "if the output doesn't have a zip extension" do
      let(:tmp_zip_file) { ::File.join(temporary_dir, "myspecial.rs") }

      before do
        expect(LogStash::PluginManager::OfflinePluginPackager).not_to receive(:package).with(anything)
      end

      it "fails to create the package" do
        expect { subject.run(cmd_args) }.to raise_error Clamp::ExecutionError, /the zip extension/
      end
    end

    context "if the file already exist" do
      before do
        FileUtils.touch(tmp_zip_file)
      end

      after do
        FileUtils.rm_f(tmp_zip_file)
      end

      context "without `--overwrite`" do
        before do
          expect(LogStash::PluginManager::OfflinePluginPackager).not_to receive(:package).with(anything)
        end

        it "should fails" do
          # ignore the first path part of tmp_zip_file because on Windows the long path is shrinked in the exception message
          expect { subject.run(cmd_args) }.to raise_error Clamp::ExecutionError, /output file destination .+#{::File.basename(tmp_zip_file)} already exist/
        end
      end

      context "with `--overwrite`" do
        let(:cmd_args) { ["--overwrite", "--output", tmp_zip_file, "logstash-input-stdin"] }

        it "succeed" do
          expect(LogStash::PluginManager::OfflinePluginPackager).to receive(:package).with(anything, tmp_zip_file)
          subject.run(cmd_args)
        end
      end
    end
  end

  context "when debugging" do
    before do
      @before_debug_value = ENV["DEBUG"]
      ENV["DEBUG"] = "1"
    end

    after do
      ENV["DEBUG"] = @before_debug_value
    end

    it "doesn't silence paquet ui reporter" do
      expect(Paquet).not_to receive(:ui=).with(Paquet::SilentUI)
      subject.run(cmd_args)
    end
  end
end
