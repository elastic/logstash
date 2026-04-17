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
require "logstash/ssl_file_tracker"

describe LogStash::SslFileTracker do
  let(:file_watch_service) do
    svc = double("file_watch_service")
    allow(svc).to receive(:register)
    allow(svc).to receive(:deregister)
    svc
  end

  subject(:tracker) { described_class.new(file_watch_service) }

  let(:file_change_event) { double("event", :kind => double("kind")) }

  def make_plugin(ssl_configs)
    klass = Class.new do
      include LogStash::Config::Mixin
      ssl_configs.each_key { |name| config name.to_sym, :validate => :path }
    end
    instance = klass.new
    ssl_configs.each { |name, val| instance.instance_variable_set("@#{name}", val) }
    instance
  end

  def rotate_symlink(link, new_target)
    tmp = "#{link}.tmp"
    File.symlink(new_target, tmp)
    File.rename(tmp, link)
  end

  def bump_mtime(path)
    future = Time.now + 1
    File.utime(future, future, path)
  end

  def make_delegator(inner_plugin)
    dbl = double("delegator")
    allow(dbl).to receive(:ruby_plugin).and_return(inner_plugin)
    dbl
  end

  def make_pipeline(id, inputs: [], filters: [], outputs: [], reloadable: true)
    double("pipeline",
      :pipeline_id => id,
      :inputs      => inputs,
      :filters     => filters,
      :outputs     => outputs,
      :reloadable? => reloadable
    )
  end

  shared_context "a registered cert file pipeline" do
    let(:cert)        { Tempfile.new("cert.pem").tap { |f| f.write("original"); f.flush } }
    let(:plugin)      { make_plugin("ssl_certificate" => cert.path) }
    let(:pipeline)    { make_pipeline(:main, inputs: [plugin]) }
    let(:captured_cb) { [] }

    before do
      allow(file_watch_service).to receive(:register) { |_, cb| captured_cb << cb }
      tracker.register(pipeline)
    end

    after { cert.close! }

    def rotate_cert
      cert.rewind
      cert.write("rotated\n")
      cert.flush
    end
  end

  shared_examples "two pipelines sharing a path" do
    it "marks both pipelines stale" do
      tracker.refresh_pipeline_symlink_stamps
      expect(tracker.stale_pipeline_ids).to contain_exactly(:p1, :p2)
    end

    it "keeps p2 stale after p1 deregisters" do
      tracker.deregister(:p1)
      tracker.refresh_pipeline_symlink_stamps
      expect(tracker.stale_pipeline_ids).to eq([:p2])
    end

    it "clears p1 stale after p1 re-registers but keeps p2 stale" do
      tracker.deregister(:p1)
      tracker.register(make_pipeline(:p1, inputs: [make_plugin("ssl_certificate" => shared_path)]))
      tracker.refresh_pipeline_symlink_stamps
      expect(tracker.stale_pipeline_ids).to eq([:p2])
    end
  end

  shared_examples "tracks delegator certs" do |plugin_slot|
    it "registers the cert path" do
      cert      = Tempfile.new("cert.pem").tap { |f| f.write("c"); f.flush }
      inner     = make_plugin("ssl_certificate" => cert.path)
      delegator = make_delegator(inner)
      pipeline  = make_pipeline(:main, plugin_slot => [delegator])

      registered = []
      allow(file_watch_service).to receive(:register) { |p, _| registered << p.to_s }
      tracker.register(pipeline)

      expect(registered).to contain_exactly(cert.path)
    ensure
      cert.close!
    end
  end

  describe "#register" do
    context "with a non-reloadable pipeline" do
      include_context "a registered cert file pipeline"

      let(:pipeline) { make_pipeline(:main, inputs: [plugin], reloadable: false) }

      it "skips non-reloadable pipelines" do
        expect(file_watch_service).not_to have_received(:register)

        rotate_cert
        tracker.refresh_pipeline_symlink_stamps
        expect(tracker.stale_pipeline_ids).to be_empty
      end
    end

    it "does not use FileWatchService when the path is a symlink" do
      Dir.mktmpdir do |dir|
        target  = File.join(dir, "cert-1.pem"); File.write(target, "original")
        symlink = File.join(dir, "cert.pem");   File.symlink(target, symlink)

        pipeline = make_pipeline(:main, inputs: [make_plugin("ssl_certificate" => symlink)])
        tracker.register(pipeline)

        expect(file_watch_service).not_to have_received(:register)
      end
    end

    it "skips Java-native plugins where ruby_plugin returns nil" do
      pipeline = make_pipeline(:main, filters: [make_delegator(nil)])
      expect { tracker.register(pipeline) }.not_to raise_error
      expect(file_watch_service).not_to have_received(:register)
    end

    it_behaves_like "tracks delegator certs", :filters
    it_behaves_like "tracks delegator certs", :outputs

    it "tracks ssl_keystore_path and ssl_truststore_path" do
      keystore   = Tempfile.new("keystore.jks").tap   { |f| f.write("ks"); f.flush }
      truststore = Tempfile.new("truststore.jks").tap { |f| f.write("ts"); f.flush }

      plugin   = make_plugin("ssl_keystore_path" => keystore.path, "ssl_truststore_path" => truststore.path)
      pipeline = make_pipeline(:main, inputs: [plugin])

      registered = []
      allow(file_watch_service).to receive(:register) { |p, _| registered << p.to_s }
      tracker.register(pipeline)

      expect(registered).to contain_exactly(keystore.path, truststore.path)
    ensure
      [keystore, truststore].each(&:close!)
    end

    it "handles ssl_certificate_authorities as array" do
      ca1 = Tempfile.new("ca1.pem").tap { |f| f.write("ca1"); f.flush }
      ca2 = Tempfile.new("ca2.pem").tap { |f| f.write("ca2"); f.flush }

      klass = Class.new do
        include LogStash::Config::Mixin
        config :ssl_certificate_authorities, :validate => :array
      end
      plugin = klass.new
      plugin.instance_variable_set("@ssl_certificate_authorities", [ca1.path, ca2.path])
      pipeline = make_pipeline(:main, inputs: [plugin])

      registered_paths = []
      allow(file_watch_service).to receive(:register) { |p, _cb| registered_paths << p.to_s }
      tracker.register(pipeline)

      expect(registered_paths).to contain_exactly(ca1.path, ca2.path)
    ensure
      [ca1, ca2].each(&:close!)
    end

    it "calls file_watch_service.register only once when two pipelines share the same cert" do
      cert = Tempfile.new("cert.pem").tap { |f| f.write("x"); f.flush }

      register_count = 0
      allow(file_watch_service).to receive(:register) { register_count += 1 }
      tracker.register(make_pipeline(:p1, inputs: [make_plugin("ssl_certificate" => cert.path)]))
      tracker.register(make_pipeline(:p2, inputs: [make_plugin("ssl_certificate" => cert.path)]))

      expect(register_count).to eq(1)
    ensure
      cert.close!
    end

    it "deduplicates relative and absolute paths pointing to the same cert" do
      Dir.mktmpdir do |dir|
        cert_path = File.join(dir, "cert.pem")
        File.write(cert_path, "x")
        relative  = Pathname.new(cert_path).relative_path_from(Pathname.new(Dir.pwd)).to_s

        register_count = 0
        allow(file_watch_service).to receive(:register) { register_count += 1 }
        tracker.register(make_pipeline(:p1, inputs: [make_plugin("ssl_certificate" => cert_path)]))
        tracker.register(make_pipeline(:p2, inputs: [make_plugin("ssl_certificate" => relative)]))

        expect(register_count).to eq(1)
      end
    end
  end

  describe "#deregister" do
    let(:cert) { Tempfile.new("cert.pem").tap { |f| f.write("x"); f.flush } }
    after { cert.close! }

    it "is a no-op for unknown ids" do
      expect { tracker.deregister(:nonexistent) }.not_to raise_error
    end

    it "cancels the watch when the last pipeline using a cert is deregistered" do
      tracker.register(make_pipeline(:main, inputs: [make_plugin("ssl_certificate" => cert.path)]))
      tracker.deregister(:main)
      expect(file_watch_service).to have_received(:deregister).with(
        satisfy { |p| p.to_s == cert.path }, anything
      )
    end

    it "does not cancel the watch when another pipeline still uses the same cert" do
      tracker.register(make_pipeline(:p1, inputs: [make_plugin("ssl_certificate" => cert.path)]))
      tracker.register(make_pipeline(:p2, inputs: [make_plugin("ssl_certificate" => cert.path)]))
      tracker.deregister(:p1)
      expect(file_watch_service).not_to have_received(:deregister)
    end
  end

  describe "#refresh_pipeline_symlink_stamps" do
    it "returns empty when no pipelines registered" do
      tracker.refresh_pipeline_symlink_stamps
      expect(tracker.stale_pipeline_ids).to be_empty
    end

    it "returns empty immediately after register" do
      cert = Tempfile.new("cert.pem").tap { |f| f.write("content"); f.flush }
      tracker.register(make_pipeline(:main, inputs: [make_plugin("ssl_certificate" => cert.path)]))
      tracker.refresh_pipeline_symlink_stamps
      expect(tracker.stale_pipeline_ids).to be_empty
    ensure
      cert.close!
    end

    context "watch mode (regular files via FileWatchService)" do
      include_context "a registered cert file pipeline"

      it "does not mark pipeline stale when file content is unchanged" do
        captured_cb.first.call(file_change_event)
        tracker.refresh_pipeline_symlink_stamps
        expect(tracker.stale_pipeline_ids).to be_empty
      end

      it "returns only the affected pipeline when one of two certs changes" do
        cert2 = Tempfile.new("cert2.pem").tap { |f| f.write("c2"); f.flush }
        tracker.register(make_pipeline(:p2, inputs: [make_plugin("ssl_certificate" => cert2.path)]))

        rotate_cert
        captured_cb.first.call(file_change_event)

        tracker.refresh_pipeline_symlink_stamps
        stale = tracker.stale_pipeline_ids
        expect(stale).to include(:main)
        expect(stale).not_to include(:p2)
      ensure
        cert2.close!
      end

      context "after cert rotation" do
        before do
          rotate_cert
          captured_cb.first.call(file_change_event)
        end

        it "returns pipeline id" do
          tracker.refresh_pipeline_symlink_stamps
          expect(tracker.stale_pipeline_ids).to eq([:main])
        end

        it "keeps pipeline stale on repeated calls until re-registered" do
          tracker.refresh_pipeline_symlink_stamps
          tracker.refresh_pipeline_symlink_stamps
          expect(tracker.stale_pipeline_ids).to eq([:main])
        end

        it "returns empty after pipeline re-registers with updated baseline" do
          tracker.deregister(:main)
          tracker.register(pipeline)
          tracker.refresh_pipeline_symlink_stamps
          expect(tracker.stale_pipeline_ids).to be_empty
        end

        it "returns empty after pipeline is deregistered" do
          tracker.deregister(:main)
          tracker.refresh_pipeline_symlink_stamps
          expect(tracker.stale_pipeline_ids).to be_empty
        end
      end
    end

    context "poll mode (symlinks)" do
      let(:dir)      { Dir.mktmpdir }
      let(:target)   { File.join(dir, "cert-1.pem").tap { |p| File.write(p, "original") } }
      let(:symlink)  { File.join(dir, "cert.pem").tap   { |p| File.symlink(target, p) } }
      let(:pipeline) { make_pipeline(:main, inputs: [make_plugin("ssl_certificate" => symlink)]) }

      before { tracker.register(pipeline) }
      after  { FileUtils.remove_entry(dir) }

      it "does not mark pipeline stale when mtime is unchanged" do
        tracker.refresh_pipeline_symlink_stamps
        expect(tracker.stale_pipeline_ids).to be_empty
      end

      it "detects symlink content change" do
        File.write(target, "rotated content")
        tracker.refresh_pipeline_symlink_stamps
        expect(tracker.stale_pipeline_ids).to eq([:main])
      end

      it "detects symlink rotation" do
        cert2 = File.join(dir, "cert-2.pem"); File.write(cert2, "rotated")
        rotate_symlink(symlink, cert2)
        bump_mtime(cert2)
        tracker.refresh_pipeline_symlink_stamps
        expect(tracker.stale_pipeline_ids).to eq([:main])
      end

      it "does not poll regular file paths" do
        cert = Tempfile.new("cert.pem").tap { |f| f.write("original"); f.flush }
        tracker.register(make_pipeline(:p2, inputs: [make_plugin("ssl_certificate" => cert.path)]))
        tracker.refresh_pipeline_symlink_stamps
        expect(tracker.stale_pipeline_ids).to be_empty
      ensure
        cert.close!
      end

      it "returns only the affected pipeline when one of two symlinks rotates" do
        target1 = File.join(dir, "cert1-v1.pem"); File.write(target1, "v1")
        link1   = File.join(dir, "cert1.pem");    File.symlink(target1, link1)
        target2 = File.join(dir, "cert2-v1.pem"); File.write(target2, "v1")
        link2   = File.join(dir, "cert2.pem");    File.symlink(target2, link2)

        tracker.register(make_pipeline(:p1, inputs: [make_plugin("ssl_certificate" => link1)]))
        tracker.register(make_pipeline(:p2, inputs: [make_plugin("ssl_certificate" => link2)]))

        File.write(target1, "v2")

        tracker.refresh_pipeline_symlink_stamps
        stale = tracker.stale_pipeline_ids
        expect(stale).to include(:p1)
        expect(stale).not_to include(:p2)
      end

      context "after symlink mtime bump" do
        before { bump_mtime(target) }

        it "returns pipeline id" do
          tracker.refresh_pipeline_symlink_stamps
          expect(tracker.stale_pipeline_ids).to eq([:main])
        end

        it "keeps pipeline stale on repeated calls until re-registered" do
          tracker.refresh_pipeline_symlink_stamps
          tracker.refresh_pipeline_symlink_stamps
          expect(tracker.stale_pipeline_ids).to eq([:main])
        end

        it "returns empty after pipeline is deregistered" do
          tracker.refresh_pipeline_symlink_stamps
          tracker.deregister(:main)
          tracker.refresh_pipeline_symlink_stamps
          expect(tracker.stale_pipeline_ids).to be_empty
        end

        it "returns empty after pipeline re-registers with updated baseline" do
          tracker.refresh_pipeline_symlink_stamps
          tracker.deregister(:main)
          tracker.register(pipeline)
          tracker.refresh_pipeline_symlink_stamps
          expect(tracker.stale_pipeline_ids).to be_empty
        end
      end

      it "detects kubernetes double-symlink rotation" do
        # Simulates the k8s Secret volumeMount layout:
        #   k8s.pem -> ..data/cert.pem -> ..2024_01_01/cert.pem
        # K8s rotation atomically repoints ..data to a new timestamp directory.
        ts1 = File.join(dir, "..2024_01_01"); Dir.mkdir(ts1)
        ts2 = File.join(dir, "..2024_01_02"); Dir.mkdir(ts2)
        File.write(File.join(ts1, "cert.pem"), "original")
        File.write(File.join(ts2, "cert.pem"), "rotated")

        data_link = File.join(dir, "..data"); File.symlink(ts1, data_link)
        cert_link = File.join(dir, "k8s.pem"); File.symlink(File.join("..data", "cert.pem"), cert_link)

        tracker.register(make_pipeline(:k8s, inputs: [make_plugin("ssl_certificate" => cert_link)]))

        tracker.refresh_pipeline_symlink_stamps
        expect(tracker.stale_pipeline_ids).to be_empty

        rotate_symlink(data_link, ts2)
        bump_mtime(File.join(ts2, "cert.pem"))
        tracker.refresh_pipeline_symlink_stamps
        expect(tracker.stale_pipeline_ids).to eq([:k8s])
      end
    end

    context "two pipelines sharing a cert" do
      let(:cert)        { Tempfile.new("cert.pem").tap { |f| f.write("v1"); f.flush } }
      let(:shared_path) { cert.path }
      let(:captured_cb) { [] }

      before do
        allow(file_watch_service).to receive(:register) { |_, cb| captured_cb << cb }
        tracker.register(make_pipeline(:p1, inputs: [make_plugin("ssl_certificate" => cert.path)]))
        tracker.register(make_pipeline(:p2, inputs: [make_plugin("ssl_certificate" => cert.path)]))
        cert.tap { |f| f.rewind; f.write("v2\n"); f.flush }
        captured_cb.first.call(file_change_event)
      end

      after { cert.close! }

      it_behaves_like "two pipelines sharing a path"
    end

    context "two pipelines sharing a symlink" do
      let(:dir)         { Dir.mktmpdir }
      let(:target)      { File.join(dir, "cert-1.pem").tap { |p| File.write(p, "original") } }
      let(:symlink)     { File.join(dir, "cert.pem").tap   { |p| File.symlink(target, p) } }
      let(:shared_path) { symlink }

      before do
        tracker.register(make_pipeline(:p1, inputs: [make_plugin("ssl_certificate" => symlink)]))
        tracker.register(make_pipeline(:p2, inputs: [make_plugin("ssl_certificate" => symlink)]))
        bump_mtime(target)
        tracker.refresh_pipeline_symlink_stamps
      end

      after { FileUtils.remove_entry(dir) }

      it_behaves_like "two pipelines sharing a path"
    end
  end
end
