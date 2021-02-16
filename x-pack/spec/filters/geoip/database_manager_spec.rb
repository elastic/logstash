# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative 'test_helper'
require "filters/geoip/database_manager"

module LogStash module Filters module Geoip
  RSpec.configure do |c|
    c.define_derived_metadata do |meta|
      meta[:aggregate_failures] = true
    end
  end

  describe DatabaseManager do
    let(:mock_geoip_plugin)  { double("geoip_plugin") }
    let(:mock_metadata)  { double("database_metadata") }
    let(:mock_download_manager)  { double("download_manager") }
    let(:db_manager) do
      manager = DatabaseManager.new(mock_geoip_plugin, DEFAULT_CITY_DB_PATH, "City", get_vendor_path)
      manager.instance_variable_set(:@metadata, mock_metadata)
      manager.instance_variable_set(:@download_manager, mock_download_manager)
      manager
    end
    let(:logger) { double("Logger") }

    context "patch database" do
      it "use CC license database as default" do
        path = db_manager.send(:patch_database_path, "")
        expect(path).to eq(DEFAULT_CITY_DB_PATH)
      end

      it "failed when default database is missing" do
        expect(db_manager).to receive(:file_exist?).and_return(false, false)
        expect { db_manager.send(:patch_database_path, "") }.to raise_error /I looked for/
      end
    end

    context "md5" do
      it "return md5 if file exists" do
        str = db_manager.send(:md5, DEFAULT_CITY_DB_PATH)
        expect(str).not_to eq("")
        expect(str).not_to be_nil
      end

      it "return empty str if file not exists" do
        file = Stud::Temporary.file.path + "/invalid"
        str = db_manager.send(:md5, file)
        expect(str).to eq("")
      end
    end

    context "check age" do
      it "should raise error when 30 days has passed" do
        expect(mock_metadata).to receive(:updated_at).and_return((Time.now - (60 * 60 * 24 * 33)).to_i)
        expect{ db_manager.send(:check_age) }.to raise_error /be compliant/
      end

      it "should give warning after 25 days" do
        expect(mock_metadata).to receive(:updated_at).and_return((Time.now - (60 * 60 * 24 * 26)).to_i)
        expect(mock_geoip_plugin).to receive(:terminate_filter).never
        expect(DatabaseManager).to receive(:logger).at_least(:once).and_return(logger)
        expect(logger).to receive(:warn)
        expect(logger).to receive(:info)

        db_manager.send(:check_age)
      end
    end

    context "execute download job" do
      it "should be false if no update" do
        original = db_manager.instance_variable_get(:@database_path)
        expect(mock_download_manager).to receive(:fetch_database).and_return([false, nil])
        allow(mock_metadata).to receive(:save_timestamp)

        expect(db_manager.send(:execute_download_job)).to be_falsey
        expect(db_manager.instance_variable_get(:@database_path)).to eq(original)
      end

      it "should return true if update" do
        original = db_manager.instance_variable_get(:@database_path)
        expect(mock_download_manager).to receive(:fetch_database).and_return([true, "NEW_PATH"])
        allow(mock_metadata).to receive(:save_timestamp)

        expect(db_manager.send(:execute_download_job)).to be_truthy
        expect(db_manager.instance_variable_get(:@database_path)).not_to eq(original)
      end

      it "should raise error when 30 days has passed" do
        allow(mock_download_manager).to receive(:fetch_database).and_raise("boom")
        expect(mock_metadata).to receive(:updated_at).and_return((Time.now - (60 * 60 * 24 * 33)).to_i)

        expect{ db_manager.send(:execute_download_job) }.to raise_error /be compliant/
      end


      it "should return false when 25 days has passed" do
        allow(mock_download_manager).to receive(:fetch_database).and_raise("boom")

        expect(mock_metadata).to receive(:updated_at).and_return((Time.now - (60 * 60 * 24 * 25)).to_i)

        expect(db_manager.send(:execute_download_job)).to be_falsey
      end
    end

    context "scheduler call" do
      it "should call plugin termination when raise error and last update > 30 days" do
        allow(mock_download_manager).to receive(:fetch_database).and_raise("boom")
        expect(mock_metadata).to receive(:updated_at).and_return((Time.now - (60 * 60 * 24 * 33)).to_i)
        expect(mock_geoip_plugin).to receive(:terminate_filter)
        db_manager.send(:call, nil, nil)
      end

      it "should not call plugin setup when database is up to date" do
        allow(mock_download_manager).to receive(:fetch_database).and_return([false, nil])
        expect(mock_metadata).to receive(:save_timestamp)
        allow(mock_geoip_plugin).to receive(:setup_filter).never
        db_manager.send(:call, nil, nil)
      end
    end

    context "clean up database" do
      let(:asn00) { get_file_path("GeoLite2-ASN_000000000.mmdb") }
      let(:asn00gz) { get_file_path("GeoLite2-ASN_000000000.gz") }
      let(:city00) { get_file_path("GeoLite2-City_000000000.mmdb") }
      let(:city00gz) { get_file_path("GeoLite2-City_000000000.gz") }
      let(:city44) { get_file_path("GeoLite2-City_4444444444.mmdb") }
      let(:city44gz) { get_file_path("GeoLite2-City_4444444444.gz") }

      before(:each) do
        [asn00, asn00gz, city00, city00gz, city44, city44gz].each { |file_path| ::File.delete(file_path) if ::File.exist?(file_path) }
      end

      it "should not delete when metadata file doesn't exist" do
        expect(mock_metadata).to receive(:exist?).and_return(false)
        allow(mock_geoip_plugin).to receive(:database_filenames).never

        db_manager.send(:clean_up_database)
      end

      it "should delete file which is not in metadata" do
        [asn00, asn00gz, city00, city00gz, city44, city44gz].each { |file_path| FileUtils.touch(file_path) }
        expect(mock_metadata).to receive(:exist?).and_return(true)
        expect(mock_metadata).to receive(:database_filenames).and_return(["GeoLite2-City_4444444444.mmdb"])

        db_manager.send(:clean_up_database)
        [asn00, asn00gz, city00, city00gz, city44gz].each { |file_path| expect(::File.exist?(file_path)).to be_falsey }
        [DEFAULT_CITY_DB_PATH, DEFAULT_ASN_DB_PATH, city44].each { |file_path| expect(::File.exist?(file_path)).to be_truthy }
      end

      it "should keep the default database" do
        expect(mock_metadata).to receive(:exist?).and_return(true)
        expect(mock_metadata).to receive(:database_filenames).and_return(["GeoLite2-City_4444444444.mmdb"])

        db_manager.send(:clean_up_database)
        [DEFAULT_CITY_DB_PATH, DEFAULT_ASN_DB_PATH].each { |file_path| expect(::File.exist?(file_path)).to be_truthy }
      end
    end

    context "setup metadata" do
      let(:db_metadata) do
        dbm = DatabaseMetadata.new("City", get_vendor_path)
        dbm.instance_variable_set(:@metadata_path, Stud::Temporary.file.path)
        dbm
      end

      let(:temp_metadata_path) { db_metadata.instance_variable_get(:@metadata_path) }

      before(:each) do
        expect(::File.empty?(temp_metadata_path)).to be_truthy
        allow(DatabaseMetadata).to receive(:new).and_return(db_metadata)
      end

      after(:each) do
        ::File.delete(SECOND_CITY_DB_PATH) if ::File.exist?(SECOND_CITY_DB_PATH)
      end

      it "create metadata when file is missing" do
        db_manager.send(:setup)
        expect(db_manager.instance_variable_get(:@database_path)).to eql(DEFAULT_CITY_DB_PATH)
        expect(db_metadata.database_path).to eql(DEFAULT_CITY_DB_PATH)
        expect(::File.exist?(temp_metadata_path)).to be_truthy
        expect(::File.empty?(temp_metadata_path)).to be_falsey
      end

      it "manager should use database path in metadata" do
        write_temp_metadata(temp_metadata_path, city2_metadata)
        copy_city_database(SECOND_CITY_DB_NAME)
        expect(db_metadata).to receive(:save_timestamp).never

        db_manager.send(:setup)
        filename = db_manager.instance_variable_get(:@database_path).split('/').last
        expect(filename).to match /#{SECOND_CITY_DB_NAME}/
      end

      it "ignore database_path in metadata if md5 does not match" do
        write_temp_metadata(temp_metadata_path, ["City","","","INVALID_MD5",SECOND_CITY_DB_NAME])
        copy_city_database(SECOND_CITY_DB_NAME)
        expect(db_metadata).to receive(:save_timestamp).never

        db_manager.send(:setup)
        filename = db_manager.instance_variable_get(:@database_path).split('/').last
        expect(filename).to match /#{DEFAULT_CITY_DB_NAME}/
      end

    end
  end
end end end