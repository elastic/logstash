# # Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# # or more contributor license agreements. Licensed under the Elastic License;
# # you may not use this file except in compliance with the Elastic License.

require_relative 'test_helper'
require "filters/geoip/database_metadata"
require "stud/temporary"

module LogStash module Filters module Geoip

  describe DatabaseMetadata, :aggregate_failures do
    let(:dbm) do
      dbm = DatabaseMetadata.new("City", get_vendor_path)
      dbm.instance_variable_set(:@metadata_path, Stud::Temporary.file.path)
      dbm
    end
    let(:temp_metadata_path) { dbm.instance_variable_get(:@metadata_path) }
    let(:logger) { double("Logger") }

    context "get all" do
      it "return multiple rows" do
        write_temp_metadata(temp_metadata_path, city2_metadata)

        expect(dbm.get_all.size).to eq(3)
      end
    end

    context "get metadata" do
      it "return metadata" do
        write_temp_metadata(temp_metadata_path, city2_metadata)

        city = dbm.get_metadata
        expect(city.size).to eq(2)

        asn = dbm.get_metadata(false)
        expect(asn.size).to eq(1)
      end

      it "return empty array when file is missing" do
        metadata = dbm.get_metadata
        expect(metadata.size).to eq(0)
      end

      it "return empty array when an empty file exist" do
        FileUtils.touch(temp_metadata_path)

        metadata = dbm.get_metadata
        expect(metadata.size).to eq(0)
      end
    end

    context "save timestamp" do
      before do
        ::File.open(DEFAULT_CITY_GZ_PATH, "w") { |f| f.write "make a non empty file" }
      end

      after do
        delete_file(DEFAULT_CITY_GZ_PATH)
      end

      it "write the current time" do
        dbm.save_timestamp(DEFAULT_CITY_DB_PATH)

        metadata = dbm.get_metadata.last
        expect(metadata[DatabaseMetadata::Column::DATABASE_TYPE]).to eq("City")
        past = metadata[DatabaseMetadata::Column::UPDATE_AT]
        expect(Time.now.to_i - past.to_i).to be < 100
        expect(metadata[DatabaseMetadata::Column::GZ_MD5]).not_to be_empty
        expect(metadata[DatabaseMetadata::Column::GZ_MD5]).to eq(md5(DEFAULT_CITY_GZ_PATH))
        expect(metadata[DatabaseMetadata::Column::MD5]).to eq(DEFAULT_CITY_DB_MD5)
        expect(metadata[DatabaseMetadata::Column::FILENAME]).to eq(DEFAULT_CITY_DB_NAME)
      end
    end

    context "database path" do
      it "return the default city database path" do
        write_temp_metadata(temp_metadata_path)

        expect(dbm.database_path).to eq(DEFAULT_CITY_DB_PATH)
      end

      it "return the last database path with valid md5" do
        write_temp_metadata(temp_metadata_path, city2_metadata)

        expect(dbm.database_path).to eq(DEFAULT_CITY_DB_PATH)
      end

      context "with ASN database type" do
        let(:dbm) do
          dbm = DatabaseMetadata.new("ASN", get_vendor_path)
          dbm.instance_variable_set(:@metadata_path, Stud::Temporary.file.path)
          dbm
        end

        it "return the default asn database path" do
          write_temp_metadata(temp_metadata_path)

          expect(dbm.database_path).to eq(DEFAULT_ASN_DB_PATH)
        end
      end

      context "with invalid database type" do
        let(:dbm) do
          dbm = DatabaseMetadata.new("???", get_vendor_path)
          dbm.instance_variable_set(:@metadata_path, Stud::Temporary.file.path)
          dbm
        end

        it "return nil if md5 not matched" do
          write_temp_metadata(temp_metadata_path)

          expect(dbm.database_path).to be_nil
        end
      end
    end

    context "gz md5" do
      it "should give the last gz md5" do
        write_temp_metadata(temp_metadata_path, ["City","","SOME_GZ_MD5","SOME_MD5",SECOND_CITY_DB_NAME])
        expect(dbm.gz_md5).to eq("SOME_GZ_MD5")
      end

      it "should give empty string if metadata is empty" do
        expect(dbm.gz_md5).to eq("")
      end
    end

    context "updated at" do
      it "should give the last update timestamp" do
        write_temp_metadata(temp_metadata_path, ["City","1611690807","SOME_GZ_MD5","SOME_MD5",SECOND_CITY_DB_NAME])
        expect(dbm.updated_at).to eq(1611690807)
      end

      it "should give 0 if metadata is empty" do
        expect(dbm.updated_at).to eq(0)
      end
    end

    context "database filenames" do
      it "should give filename in .mmdb .tgz" do
        write_temp_metadata(temp_metadata_path)
        expect(dbm.database_filenames).to match_array([DEFAULT_CITY_DB_NAME, DEFAULT_ASN_DB_NAME,
                                                       'GeoLite2-City.tgz', 'GeoLite2-ASN.tgz'])
      end
    end

    context "exist" do
      it "should be false because Stud create empty temp file" do
        expect(dbm.exist?).to be_falsey
      end

      it "should be true if temp file has content" do
        ::File.open(temp_metadata_path, "w") { |f| f.write("something") }

        expect(dbm.exist?).to be_truthy
      end
    end

  end
end end end