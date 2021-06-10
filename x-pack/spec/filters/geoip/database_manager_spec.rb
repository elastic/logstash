# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative 'test_helper'
require "filters/geoip/database_manager"

describe LogStash::Filters::Geoip do

  describe 'DatabaseManager', :aggregate_failures do
    let(:mock_geoip_plugin)  { double("geoip_plugin") }
    let(:mock_metadata)  { double("database_metadata") }
    let(:mock_download_manager)  { double("download_manager") }
    let(:mock_scheduler)  { double("scheduler") }
    let(:db_manager) do
      manager = Class.new(LogStash::Filters::Geoip::DatabaseManager).instance
      manager.instance_variable_set(:@metadata, mock_metadata)
      manager.instance_variable_set(:@download_manager, mock_download_manager)
      manager.instance_variable_set(:@scheduler, mock_scheduler)
      manager
    end
    let(:logger) { double("Logger") }

    CITY = LogStash::Filters::Geoip::CITY
    ASN = LogStash::Filters::Geoip::ASN
    CC = LogStash::Filters::Geoip::CC

    before do
      stub_const('LogStash::Filters::Geoip::DownloadManager::GEOIP_ENDPOINT', "https://somewhere.dev")
      allow(mock_geoip_plugin).to receive(:update_filter)
    end

    after do
      delete_file(metadata_path)
    end

    context "initialize" do
      it "should set the initial state to cc database" do
        states = db_manager.instance_variable_get(:@states)
        expect(states[CITY].is_eula).to be_falsey
        expect(states[CITY].database_path).to eql(states[CITY].cc_database_path)
        expect(::File.exist?(states[CITY].cc_database_path)).to be_truthy
        expect(states[ASN].is_eula).to be_falsey
        expect(states[ASN].database_path).to eql(states[ASN].cc_database_path)
        expect(::File.exist?(states[ASN].cc_database_path)).to be_truthy
      end

      context "when metadata exists" do
        before do
          copy_cc(get_dir_path(second_dirname))
          rewrite_temp_metadata(metadata_path, [city2_metadata])
        end

        it "should use database record in metadata" do
          states = db_manager.instance_variable_get(:@states)
          expect(states[CITY].is_eula).to be_truthy
          expect(states[CITY].database_path).to include second_dirname
        end
      end

      context "when metadata exists but database is deleted manually" do
        let(:db_manager) { Class.new(LogStash::Filters::Geoip::DatabaseManager).instance }

        before do
          rewrite_temp_metadata(metadata_path, [city2_metadata])
        end

        it "should return metadata path" do
          states = db_manager.instance_variable_get(:@states)
          expect(states[CITY].is_eula).to be_truthy
          expect(states[CITY].database_path).to be_nil
        end
      end
    end

    context "execute download job" do
      let(:valid_city_fetch) { [CITY, true, second_dirname, second_city_db_path] }
      let(:valid_asn_fetch) { [ASN, true, second_dirname, second_asn_db_path] }
      let(:invalid_city_fetch) { [CITY, false, nil, nil] }

      context "plugin is set" do
        let(:db_manager) do
          manager = Class.new(LogStash::Filters::Geoip::DatabaseManager).instance
          manager.instance_variable_set(:@metadata, mock_metadata)
          manager.instance_variable_set(:@download_manager, mock_download_manager)
          manager.instance_variable_set(:@scheduler, mock_scheduler)
          manager.instance_variable_get(:@states)[CITY].plugins.push(mock_geoip_plugin)
          manager.instance_variable_get(:@states)[CITY].is_eula = true
          manager.instance_variable_get(:@states)[ASN].plugins.push(mock_geoip_plugin)
          manager.instance_variable_get(:@states)[ASN].is_eula = true
          manager
        end

        it "should update states when new downloads are valid" do
          expect(mock_download_manager).to receive(:fetch_database).and_return([valid_city_fetch, valid_asn_fetch])
          expect(mock_metadata).to receive(:save_metadata).at_least(:twice)
          expect(mock_geoip_plugin).to receive(:update_filter).with(:update, instance_of(String)).at_least(:twice)
          expect(mock_metadata).to receive(:update_timestamp).never
          expect(db_manager).to receive(:check_age)
          expect(db_manager).to receive(:clean_up_database)

          db_manager.send(:execute_download_job)
          expect(db_manager.database_path(CITY)).to match /#{second_dirname}\/#{default_city_db_name}/
          expect(db_manager.database_path(ASN)).to match /#{second_dirname}\/#{default_asn_db_name}/
        end
      end

      it "should update single state when new downloads are partially valid" do
        expect(mock_download_manager).to receive(:fetch_database).and_return([invalid_city_fetch, valid_asn_fetch])
        expect(mock_metadata).to receive(:save_metadata).with(ASN, second_dirname, true).at_least(:once)
        expect(mock_metadata).to receive(:update_timestamp).never
        expect(db_manager).to receive(:check_age)
        expect(db_manager).to receive(:clean_up_database)

        db_manager.send(:execute_download_job)
        expect(db_manager.database_path(CITY)).to match /#{CC}\/#{default_city_db_name}/
        expect(db_manager.database_path(ASN)).to match /#{second_dirname}\/#{default_asn_db_name}/
      end

      it "should update single state and single metadata timestamp when one database got update" do
        expect(mock_download_manager).to receive(:fetch_database).and_return([valid_asn_fetch])
        expect(mock_metadata).to receive(:save_metadata).with(ASN, second_dirname, true).at_least(:once)
        expect(mock_metadata).to receive(:update_timestamp).with(CITY).at_least(:once)
        expect(db_manager).to receive(:check_age)
        expect(db_manager).to receive(:clean_up_database)

        db_manager.send(:execute_download_job)
        expect(db_manager.database_path(CITY)).to match /#{CC}\/#{default_city_db_name}/
        expect(db_manager.database_path(ASN)).to match /#{second_dirname}\/#{default_asn_db_name}/
      end

      it "should update metadata timestamp for the unchange (no update)" do
        expect(mock_download_manager).to receive(:fetch_database).and_return([])
        expect(mock_metadata).to receive(:save_metadata).never
        expect(mock_metadata).to receive(:update_timestamp).at_least(:twice)
        expect(db_manager).to receive(:check_age)
        expect(db_manager).to receive(:clean_up_database)

        db_manager.send(:execute_download_job)
        expect(db_manager.database_path(CITY)).to match /#{CC}\/#{default_city_db_name}/
        expect(db_manager.database_path(ASN)).to  match /#{CC}\/#{default_asn_db_name}/
      end

      it "should not update metadata when fetch database throw exception" do
        expect(mock_download_manager).to receive(:fetch_database).and_raise('boom')
        expect(db_manager).to receive(:check_age)
        expect(db_manager).to receive(:clean_up_database)
        expect(mock_metadata).to receive(:save_metadata).never

        db_manager.send(:execute_download_job)
      end
    end

    context "check age" do
      context "eula database" do
        let(:db_manager) do
          manager = Class.new(LogStash::Filters::Geoip::DatabaseManager).instance
          manager.instance_variable_set(:@metadata, mock_metadata)
          manager.instance_variable_set(:@download_manager, mock_download_manager)
          manager.instance_variable_set(:@scheduler, mock_scheduler)
          manager.instance_variable_get(:@states)[CITY].plugins.push(mock_geoip_plugin)
          manager.instance_variable_get(:@states)[CITY].is_eula = true
          manager.instance_variable_get(:@states)[ASN].plugins.push(mock_geoip_plugin)
          manager.instance_variable_get(:@states)[ASN].is_eula = true
          manager
        end

        it "should give warning after 25 days" do
          expect(mock_metadata).to receive(:check_at).and_return((Time.now - (60 * 60 * 24 * 26)).to_i).at_least(:twice)
          expect(mock_geoip_plugin).to receive(:update_filter).never
          allow(LogStash::Filters::Geoip::DatabaseManager).to receive(:logger).at_least(:once).and_return(logger)
          expect(logger).to receive(:warn).at_least(:twice)

          db_manager.send(:check_age)
        end

        it "should log error and update plugin filter when 30 days has passed" do
          expect(mock_metadata).to receive(:check_at).and_return((Time.now - (60 * 60 * 24 * 33)).to_i).at_least(:twice)
          allow(LogStash::Filters::Geoip::DatabaseManager).to receive(:logger).at_least(:once).and_return(logger)
          expect(logger).to receive(:error).at_least(:twice)
          expect(mock_geoip_plugin).to receive(:update_filter).with(:expire).at_least(:twice)

          db_manager.send(:check_age)
        end
      end

      context "cc database" do
        it "should not give warning after 25 days" do
          expect(mock_geoip_plugin).to receive(:update_filter).never
          expect(logger).to receive(:warn).never

          db_manager.send(:check_age)
        end

        it "should not log error when 30 days has passed" do
          expect(logger).to receive(:error).never
          expect(mock_geoip_plugin).to receive(:update_filter).never

          db_manager.send(:check_age)
        end
      end
    end

    context "clean up database" do
      let(:dirname) { "0123456789" }
      let(:dirname2) { "9876543210" }
      let(:dir_path) { get_dir_path(dirname) }
      let(:dir_path2) { get_dir_path(dirname2) }
      let(:asn00) { get_file_path(dirname, default_asn_db_name) }
      let(:city00) { get_file_path(dirname, default_city_db_name) }
      let(:asn02) { get_file_path(dirname2, default_asn_db_name) }
      let(:city02) { get_file_path(dirname2, default_city_db_name) }


      before(:each) do
        FileUtils.mkdir_p [dir_path, dir_path2]
      end

      it "should delete file which is not in metadata" do
        FileUtils.touch [asn00, city00, asn02, city02]
        expect(mock_metadata).to receive(:dirnames).and_return([dirname])

        db_manager.send(:clean_up_database)

        [asn02, city02].each { |file_path| expect(::File.exist?(file_path)).to be_falsey }
        [get_dir_path(CC), asn00, city00].each { |file_path| expect(::File.exist?(file_path)).to be_truthy }
      end
    end

    context "subscribe database path" do
      it "should return user input path" do
        path = db_manager.subscribe_database_path(CITY, default_city_db_path, mock_geoip_plugin)
        expect(db_manager.instance_variable_get(:@states)[CITY].plugins.size).to eq(0)
        expect(path).to eq(default_city_db_path)
      end

      it "should return database path in state if no user input" do
        expect(db_manager.instance_variable_get(:@states)[CITY].plugins.size).to eq(0)
        allow(db_manager).to receive(:trigger_download)
        path = db_manager.subscribe_database_path(CITY, nil, mock_geoip_plugin)
        expect(db_manager.instance_variable_get(:@states)[CITY].plugins.size).to eq(1)
        expect(path).to eq(default_city_db_path)
      end

      context "when eula database is expired" do
        let(:db_manager) do
          manager = Class.new(LogStash::Filters::Geoip::DatabaseManager).instance
          manager.instance_variable_set(:@download_manager, mock_download_manager)
          manager.instance_variable_set(:@scheduler, mock_scheduler)
          manager
        end

        before do
          rewrite_temp_metadata(metadata_path, [city_expired_metadata])
        end

        it "should return nil" do
          allow(mock_download_manager).to receive(:fetch_database).and_raise("boom")
          expect(db_manager.instance_variable_get(:@states)[CITY].plugins.size).to eq(0)
          path = db_manager.subscribe_database_path(CITY, nil, mock_geoip_plugin)
          expect(db_manager.instance_variable_get(:@states)[CITY].plugins.size).to eq(1)
          expect(path).to be_nil
        end
      end
    end

    context "unsubscribe" do
      let(:db_manager) do
        manager = Class.new(LogStash::Filters::Geoip::DatabaseManager).instance
        manager.instance_variable_set(:@metadata, mock_metadata)
        manager.instance_variable_set(:@download_manager, mock_download_manager)
        manager.instance_variable_set(:@scheduler, mock_scheduler)
        manager.instance_variable_get(:@states)[CITY].plugins.push(mock_geoip_plugin)
        manager.instance_variable_get(:@states)[CITY].is_eula = true
        manager
      end

      it "should remove plugin in state" do
        db_manager.unsubscribe_database_path(CITY, mock_geoip_plugin)
        expect(db_manager.instance_variable_get(:@states)[CITY].plugins.size).to eq(0)
      end
    end

  end
end