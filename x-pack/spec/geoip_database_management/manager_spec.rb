# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

describe LogStash::GeoipDatabaseManagement::Manager, aggregate_failures: true, verify_stubs: true do

  def write_dummy_mmdb(type, path)
    FileUtils.mkdir_p(File::dirname(path))
    File.open(path, "w:BINARY") do |handle|
      handle.write("#{type}\xab\xcd\xefMaxMind.com#{type}".force_encoding("BINARY"))
    end
  end

  let(:manager_instance) do
    apply_settings(settings_overrides) do |applied_settings|
      stub_const("LogStash::SETTINGS", applied_settings)
      Class.new(described_class) do
        public :setup
        public :shutdown!
        public :current_db_info
        public :current_state
        public :execute_download_job
        public :metadata
        public :downloader
      end.instance
    end
  end

  let(:constants) { LogStash::GeoipDatabaseManagement::Constants }

  let(:settings_overrides) do
    {
      'path.data' => settings_path_data,
    }
  end
  let(:settings_path_data) { Stud::Temporary.directory }
  let(:geoip_data_path) { ::File.expand_path("geoip_database_management", settings_path_data)}
  let(:geoip_metadata_path) { ::File.expand_path("metadata.csv", geoip_data_path) }

  let(:metadata_contents) { nil }
  before(:each) do
    ::FileUtils.mkdir_p(::File.dirname(geoip_metadata_path))
    ::File.write(geoip_metadata_path, metadata_contents) unless metadata_contents.nil?
  end

  after(:each) do
    manager_instance.shutdown!
    FileUtils.rm_rf(settings_path_data)
  end

  shared_context "existing databases from metadata" do
    let(:existing_dirname) { (Time.now.to_i - 1000).to_s }

    let(:existing_city_db_check_at) { Time.now.to_i - 100 }
    let(:existing_city_gzmd5) { SecureRandom::hex(20) }
    let(:existing_city_db_path) { ::File.join(geoip_data_path, existing_dirname, "GeoLite2-City.mmdb") }

    let(:existing_asn_db_check_at) { Time.now.to_i - 100 }
    let(:existing_asn_gzmd5) { SecureRandom::hex(20) }
    let(:existing_asn_db_path) { ::File.join(geoip_data_path, existing_dirname, "GeoLite2-ASN.mmdb") }

    before(:each) do
      write_dummy_mmdb(constants::CITY, existing_city_db_path) unless existing_city_db_path.nil?
      write_dummy_mmdb(constants::ASN, existing_asn_db_path) unless existing_asn_db_path.nil?
    end

    let(:metadata_contents) do
      <<~EOMETA
        #{constants::CITY},#{existing_city_db_check_at},#{existing_city_gzmd5},#{existing_dirname}
        #{constants::ASN},#{existing_asn_db_check_at},#{existing_asn_gzmd5},#{existing_dirname}
      EOMETA
    end
  end

  context "pre-use" do
    before(:each) do
      expect_any_instance_of(described_class).to_not receive(:execute_download_job)
    end
    it 'is not running' do
      expect(manager_instance).to_not be_running
    end
    context "when disabled" do
      let(:settings_overrides) { super().merge('xpack.geoip.downloader.enabled' => false) }

      include_context "existing databases from metadata"

      let(:mock_logger) { double('logger').as_null_object }
      before(:each) do
        allow(described_class).to receive(:logger).and_return(mock_logger)
      end

      it 'logs info about removing managed databases' do
        manager_instance # instantiate

        expect(mock_logger).to have_received(:info).with(a_string_including "removing managed databases from disk")
      end
      it 'removes on-disk metadata' do
        manager_instance # instantiate

        expect(manager_instance.metadata).to_not exist
        expect(Pathname(geoip_metadata_path)).to_not be_file
      end
      it 'removes on-disk databases' do
        manager_instance # instantiate

        expect(Pathname(existing_city_db_path)).to_not be_file
        expect(Pathname(existing_asn_db_path)).to_not be_file
      end
    end
  end

  context "once started" do
    before(:each) do
      allow(manager_instance).to receive(:execute_download_job).and_return(nil)
      manager_instance.send(:ensure_started!)
    end
    it 'is running' do
      expect(manager_instance).to be_running
      expect(manager_instance).to have_received(:execute_download_job)
    end
    it 'has a data directory' do
      expect(Pathname(geoip_data_path)).to be_directory
    end
    it 'has metadata' do
      expect(Pathname(::File.expand_path("metadata.csv", geoip_data_path))).to be_file
    end
  end

  context "#supported_database_types" do
    subject(:supported_database_types) { manager_instance.supported_database_types }
    it 'includes City' do
      expect(supported_database_types).to include(constants::CITY)
    end
    it 'includes ASN' do
      expect(supported_database_types).to include(constants::ASN)
    end
    it 'returns only frozen strings' do
      expect(supported_database_types).to all( be_a_kind_of String )
      expect(supported_database_types).to all( be_frozen )
    end
  end

  context "#subscribe_database_path" do

    context "and manager is not enabled" do
      let(:settings_overrides) { super().merge('xpack.geoip.downloader.enabled' => false) }
      it "returns nil" do
        expect(manager_instance.subscribe_database_path(constants::CITY)).to be_nil
      end
    end

    shared_examples "active subscription" do |database_type|
      it 'receives expiry notifications' do
        allow(subscription).to receive(:notify).and_call_original

        manager_instance.current_state(database_type).expire!

        expect(subscription)
          .to have_received(:notify)
          .with(an_object_having_attributes({:expired? => true,
                                             :path => nil,
                                             :removed? => true}))
      end
      it 'receives update notifications' do
        allow(subscription).to receive(:notify).and_call_original

        updated_db_path = ::File.join(geoip_data_path, Time.now.to_i.to_s, "GeoLite2-#{database_type}.mmdb")
        write_dummy_mmdb(database_type, updated_db_path)

        manager_instance.current_state(database_type).update!(updated_db_path)

        expect(subscription)
          .to have_received(:notify)
                .with(an_object_having_attributes({:expired? => false,
                                                   :path => updated_db_path}))
      end
    end

    context "when metadata exists" do
      include_context "existing databases from metadata"

      before(:each) do
        allow(manager_instance).to receive(:execute_download_job).and_return(nil)
      end

      context "the returned subscription" do
        subject(:subscription) { manager_instance.subscribe_database_path(constants::CITY) }

        it 'carries the path of the DB from metadata' do
          expect(subscription.value).to have_attributes(:path => existing_city_db_path)
        end

        include_examples "active subscription", LogStash::GeoipDatabaseManagement::Constants::CITY
      end

      context "and metadata references an mmdb that has been removed" do
        let(:existing_city_db_path) { nil } # prevent write

        context "the returned subscription" do
          subject(:subscription) { manager_instance.subscribe_database_path(constants::CITY) }

          it 'indicates that the DB has been removed' do
            expect(subscription.value).to be_removed
          end

          include_examples "active subscription", LogStash::GeoipDatabaseManagement::Constants::CITY
        end
      end

      context "and metadata does not contain an entry for the specified DB" do
        let(:metadata_contents) do
          <<~EOMETA
            #{constants::ASN},#{existing_asn_db_check_at},#{existing_asn_gzmd5},#{existing_dirname}
          EOMETA
        end
        context "the returned subscription" do
          subject(:subscription) { manager_instance.subscribe_database_path(constants::CITY) }

          it 'indicates that the DB is pending' do
            expect(subscription.value).to be_pending
          end

          include_examples "active subscription", LogStash::GeoipDatabaseManagement::Constants::CITY
        end
      end
    end

    context "when metadata does not yet exist" do
      before(:each) do
        allow(manager_instance).to receive(:execute_download_job).and_return(nil)
      end

      context "the returned subscription" do
        subject(:subscription) { manager_instance.subscribe_database_path(constants::CITY) }

        it 'is marked as pending' do
          expect(subscription.value).to be_pending
        end

        include_examples "active subscription", LogStash::GeoipDatabaseManagement::Constants::CITY
      end
    end
  end

  context "execute_download_job" do
    let(:mock_logger) { double('logger').as_null_object }
    before(:each) do
      allow(manager_instance).to receive(:logger).and_return(mock_logger)
      expect(manager_instance).to receive(:downloader).and_return(mock_downloader)
    end

    let(:downloader_response) { [] }
    let(:mock_downloader) do
      double("downloader").tap do |downloader|
        allow(downloader).to receive(:fetch_databases).with(constants::DB_TYPES).and_return(downloader_response)
        allow(downloader).to receive(:uuid).and_return(SecureRandom.uuid)
      end
    end

    let(:updated_dirname) { (Time.now.to_i - 1).to_s }
    let(:updated_city_db_path) { ::File.join(geoip_data_path, updated_dirname, "GeoLite2-City.mmdb")}
    let(:updated_asn_db_path) { ::File.join(geoip_data_path, updated_dirname, "GeoLite2-ASN.mmdb")}

    shared_examples "ASN near expiry warning" do
      context "when a near-expiry ASN database is not succesfully updated" do
        let(:existing_asn_db_check_at) { Time.now.to_i - (27 * 24 * 60 * 60) } # 27 days ago

        it 'retains ASN state' do
          allow(manager_instance.current_state(constants::ASN)).to receive(:update!).and_call_original

          manager_instance.execute_download_job

          expected_asn_attributes = {
            :path => existing_asn_db_path, :pending? => false, :expired? => false, :removed? => false
          }
          expect(manager_instance.current_db_info(constants::ASN)).to have_attributes(expected_asn_attributes)
          expect(manager_instance.current_state(constants::ASN)).to_not have_received(:update!)
        end

        it "emits a warning log about pending ASN expiry" do
          manager_instance.execute_download_job

          expect(manager_instance.logger).to have_received(:warn).with(a_string_including "MaxMind GeoIP ASN database hasn't been synchronized in 27 days")
        end
      end
    end

    shared_examples "ASN past expiry eviction" do
      context "when a past-expiry ASN database is not successfully updated" do
        let(:existing_asn_db_check_at) { Time.now.to_i - (31 * 24 * 60 * 60) } # 31 days ago

        it 'expires the ASN state' do
          allow(manager_instance.current_state(constants::ASN)).to receive(:expire!).and_call_original

          manager_instance.execute_download_job

          expected_asn_attributes = {
            :path => nil, :pending? => false, :expired? => true, :removed? => true
          }
          expect(manager_instance.current_db_info(constants::ASN)).to have_attributes(expected_asn_attributes)
          expect(manager_instance.current_state(constants::ASN)).to have_received(:expire!)
        end

        it "emits an error log about ASN expiry eviction" do
          manager_instance.execute_download_job

          expect(manager_instance.logger).to have_received(:error).with(a_string_including("MaxMind GeoIP ASN database hasn't been synchronized in 31 days").and(including("removed")))
        end

        it "removes the expired ASN dbpath from metadata" do
          manager_instance.execute_download_job
          expect(manager_instance.metadata.database_path(constants::ASN)).to be_nil
        end
      end
    end

    shared_examples "ASN updated" do
      it "updates ASN state" do
        allow(manager_instance.current_state(constants::ASN)).to receive(:update!).and_call_original

        manager_instance.execute_download_job

        manager_instance.current_db_info(constants::ASN).tap do |asn_db_info|
          expect(asn_db_info.path).to eq(updated_asn_db_path)
          expect(asn_db_info).to_not be_pending
          expect(asn_db_info).to_not be_expired
          expect(asn_db_info).to_not be_removed
        end

        expect(manager_instance.current_state(constants::ASN)).to have_received(:update!).with(updated_asn_db_path)
      end
      it "updates ASN metadata" do
        manager_instance.execute_download_job

        expect(manager_instance.metadata.database_path(constants::ASN)).to eq(updated_asn_db_path)
        expect(manager_instance.metadata.check_at(constants::ASN)).to satisfy { |x| Time.now.to_i - x <= 1 }
      end
    end

    shared_examples "ASN unchanged" do
      it "retains ASN state" do
        allow(manager_instance.current_state(constants::ASN)).to receive(:update!).and_call_original

        manager_instance.execute_download_job

        manager_instance.current_db_info(constants::ASN).tap do |asn_db_info|
          expect(asn_db_info.path).to eq(existing_asn_db_path)
          expect(asn_db_info).to_not be_pending
          expect(asn_db_info).to_not be_expired
          expect(asn_db_info).to_not be_removed
        end

        expect(manager_instance.current_state(constants::ASN)).to_not have_received(:update!)
      end
      it "updates ASN metadata check_at" do
        manager_instance.execute_download_job

        expect(manager_instance.metadata.database_path(constants::ASN)).to eq(existing_asn_db_path)
        expect(manager_instance.metadata.check_at(constants::ASN)).to satisfy { |x| Time.now.to_i - x <= 1 }
      end
    end

    shared_examples "ASN errored" do
      it "retains ASN state" do
        allow(manager_instance.current_state(constants::ASN)).to receive(:update!).and_call_original

        manager_instance.execute_download_job

        manager_instance.current_db_info(constants::ASN).tap do |asn_db_info|
          expect(asn_db_info.path).to eq(existing_asn_db_path)
          expect(asn_db_info).to_not be_pending
          expect(asn_db_info).to_not be_expired
          expect(asn_db_info).to_not be_removed
        end

        expect(manager_instance.current_state(constants::ASN)).to_not have_received(:update!)
      end
      it "retains ASN metadata check_at" do
        manager_instance.execute_download_job

        expect(manager_instance.metadata.database_path(constants::ASN)).to eq(existing_asn_db_path)
        expect(manager_instance.metadata.check_at(constants::ASN)).to eq(existing_asn_db_check_at)
      end
    end

    shared_examples "City updated" do
      it "updates City state" do
        allow(manager_instance.current_state(constants::CITY)).to receive(:update!).and_call_original

        manager_instance.execute_download_job

        manager_instance.current_db_info(constants::CITY).tap do |city_db_info|
          expect(city_db_info.path).to eq(updated_city_db_path)
          expect(city_db_info).to_not be_pending
          expect(city_db_info).to_not be_expired
          expect(city_db_info).to_not be_removed
        end

        expect(manager_instance.current_state(constants::CITY)).to have_received(:update!).with(updated_city_db_path)
      end
      it "updates City metadata" do
        manager_instance.execute_download_job

        expect(manager_instance.metadata.database_path(constants::CITY)).to eq(updated_city_db_path)
        expect(manager_instance.metadata.check_at(constants::CITY)).to satisfy { |x| Time.now.to_i - x <= 1 }
      end
    end

    shared_examples "City unchanged" do
      it "retains City state" do
        allow(manager_instance.current_state(constants::CITY)).to receive(:update!).and_call_original

        manager_instance.execute_download_job

        manager_instance.current_db_info(constants::CITY).tap do |city_db_info|
          expect(city_db_info.path).to eq(existing_city_db_path)
          expect(city_db_info).to_not be_pending
          expect(city_db_info).to_not be_expired
          expect(city_db_info).to_not be_removed
        end

        expect(manager_instance.current_state(constants::CITY)).to_not have_received(:update!)
      end
      it "updates City metadata check_at" do
        manager_instance.execute_download_job

        expect(manager_instance.metadata.database_path(constants::CITY)).to eq(existing_city_db_path)
        expect(manager_instance.metadata.check_at(constants::CITY)).to satisfy { |x| Time.now.to_i - x <= 1 }
      end
    end

    shared_examples "City errored" do
      it "retains City state" do
        allow(manager_instance.current_state(constants::CITY)).to receive(:update!).and_call_original

        manager_instance.execute_download_job

        manager_instance.current_db_info(constants::CITY).tap do |city_db_info|
          expect(city_db_info.path).to eq(existing_city_db_path)
          expect(city_db_info).to_not be_pending
          expect(city_db_info).to_not be_expired
          expect(city_db_info).to_not be_removed
        end

        expect(manager_instance.current_state(constants::CITY)).to_not have_received(:update!)
      end
      it "retains City metadata check_at" do
        manager_instance.execute_download_job

        expect(manager_instance.metadata.database_path(constants::CITY)).to eq(existing_city_db_path)
        expect(manager_instance.metadata.check_at(constants::CITY)).to eq(existing_city_db_check_at)
      end
    end

    context "when downloader has updates for all" do
      include_context "existing databases from metadata"

      let(:updated_city_fetch) { [constants::CITY, true, updated_dirname, updated_city_db_path] }
      let(:updated_asn_fetch) { [constants::ASN, true, updated_dirname, updated_asn_db_path] }
      let(:downloader_response) do
        [
          updated_city_fetch,
          updated_asn_fetch
        ]
      end

      before(:each) do
        manager_instance.setup
        write_dummy_mmdb(constants::CITY, updated_city_db_path)
        write_dummy_mmdb(constants::ASN, updated_asn_db_path)
      end

      include_examples "City updated"
      include_examples "ASN updated"
    end

    context "when downloader has updates for City, but ASN is unchanged" do
      include_context "existing databases from metadata"

      let(:updated_city_fetch) { [constants::CITY, true, updated_dirname, updated_city_db_path] }

      # implementation detail: the downloader _excludes_ confirmed-same entries from the response
      let(:downloader_response) do
        [
          updated_city_fetch
        ]
      end

      before(:each) do
        manager_instance.setup
        write_dummy_mmdb(constants::CITY, updated_city_db_path)
      end

      include_examples "City updated"
      include_examples "ASN unchanged"
    end

    context "when downloader has updates for City, but ASN has errors" do
      include_context "existing databases from metadata"

      let(:updated_city_fetch) { [constants::CITY, true, updated_dirname, updated_city_db_path] }
      let(:updated_asn_fetch) { [constants::ASN, false, nil, nil] }

      # implementation detail: the downloader _excludes_ confirmed-same entries from the response
      let(:downloader_response) do
        [
          updated_city_fetch,
          updated_asn_fetch
        ]
      end

      before(:each) do
        manager_instance.setup
        write_dummy_mmdb(constants::CITY, updated_city_db_path)
      end

      include_examples "City updated"
      include_examples "ASN errored"
      include_examples "ASN near expiry warning"
      include_examples "ASN past expiry eviction"
    end

    context "when downloader has no changes" do
      include_context "existing databases from metadata"

      before(:each) do
        manager_instance.setup
      end

      include_examples "City unchanged"
      include_examples "ASN unchanged"
    end

    context "when downloader is exceptional" do
      include_context "existing databases from metadata"

      before(:each) do
        expect(mock_downloader).to receive(:fetch_databases).with(constants::DB_TYPES).and_raise(RuntimeError)
        manager_instance.setup
      end

      include_examples "City errored"
      include_examples "ASN errored"
      include_examples "ASN near expiry warning"
      include_examples "ASN past expiry eviction"
    end
  end
end