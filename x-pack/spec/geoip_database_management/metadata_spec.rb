# # Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# # or more contributor license agreements. Licensed under the Elastic License;
# # you may not use this file except in compliance with the Elastic License.

require 'geoip_database_management/manager'
require 'geoip_database_management/metadata'
require 'geoip_database_management/data_path'
require 'geoip_database_management/util'

describe LogStash::GeoipDatabaseManagement::Metadata, :aggregate_failures do
  let(:temp_metadata_path) { Stud::Temporary.directory }
  let(:data_path) { LogStash::GeoipDatabaseManagement::DataPath.new(temp_metadata_path) }
  let(:dbm) { described_class.new(data_path) }
  let(:logger) { double("Logger").as_null_object }

  context "get all" do
    it "returns multiple rows" do
      dbm.save_metadata(LogStash::GeoipDatabaseManagement::CITY, "#{Time.now.to_i - 1}", gz_md5: SecureRandom.hex(40))
      dbm.save_metadata(LogStash::GeoipDatabaseManagement::ASN, "#{Time.now.to_i}", gz_md5: SecureRandom.hex(40))

      expect(dbm.get_all.size).to eq(2)
    end
  end

  context "get metadata" do
    context "when populated file exists" do
      before(:each) do
        dbm.save_metadata(LogStash::GeoipDatabaseManagement::CITY, "#{Time.now.to_i - 1}", gz_md5: SecureRandom.hex(40))
        dbm.save_metadata(LogStash::GeoipDatabaseManagement::ASN, "#{Time.now.to_i}", gz_md5: SecureRandom.hex(40))
      end
      it "returns matching metadata" do
        city_rows = dbm.get_metadata(LogStash::GeoipDatabaseManagement::CITY)
        expect(city_rows.size).to eq(1)
        expect(city_rows).to all satisfy {|row| row[described_class::Column::DATABASE_TYPE] == LogStash::GeoipDatabaseManagement::CITY }

        asn_rows = dbm.get_metadata(LogStash::GeoipDatabaseManagement::ASN)
        expect(asn_rows.size).to eq(1)
        expect(asn_rows).to all satisfy {|row| row[described_class::Column::DATABASE_TYPE] == LogStash::GeoipDatabaseManagement::ASN }
      end
    end

    context "when file does not exist" do
      it "returns empty results" do
        city_rows = dbm.get_metadata(LogStash::GeoipDatabaseManagement::CITY)
        expect(city_rows).to be_empty

        asn_rows = dbm.get_metadata(LogStash::GeoipDatabaseManagement::ASN)
        expect(asn_rows).to be_empty
      end
    end

    context "when empty file exists" do
      before(:each) do
        FileUtils.touch(temp_metadata_path)
      end
      it "returns empty results" do
        city_rows = dbm.get_metadata(LogStash::GeoipDatabaseManagement::CITY)
        expect(city_rows).to be_empty

        asn_rows = dbm.get_metadata(LogStash::GeoipDatabaseManagement::ASN)
        expect(asn_rows).to be_empty
      end
    end

    context "saving" do
      let(:database_dirname) { "#{Time.now.to_i}" }
      let(:database_gz_md5) { "1bad1dea" }
      let(:database_db_md5) { "0f1c1a17" }
      before(:each) do
        dbm.save_metadata(LogStash::GeoipDatabaseManagement::CITY, database_dirname, gz_md5: database_gz_md5)
      end

      it "saves the metadata" do
        metadata = dbm.get_metadata(LogStash::GeoipDatabaseManagement::CITY).last

        expect(metadata[described_class::Column::DATABASE_TYPE]).to eq(LogStash::GeoipDatabaseManagement::CITY)

        check_at = metadata[described_class::Column::CHECK_AT]
        expect(Time.now.to_i - check_at.to_i).to be < 100

        expect(metadata[described_class::Column::DIRNAME]).to eq(database_dirname)
        expect(metadata[described_class::Column::GZ_MD5]).to eq(database_gz_md5)
      end
    end
  end
end