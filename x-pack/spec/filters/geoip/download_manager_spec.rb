# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative 'test_helper'
require 'fileutils'
require "filters/geoip/download_manager"
require "filters/geoip/database_manager"

describe LogStash::Filters::Geoip do

  describe 'DownloadManager', :aggregate_failures do
    let(:mock_metadata)  { double("database_metadata") }
    let(:download_manager) do
      manager = LogStash::Filters::Geoip::DownloadManager.new(mock_metadata)
      manager
    end
    let(:database_type) { LogStash::Filters::Geoip::CITY }
    let(:logger) { double("Logger") }

    GEOIP_STAGING_HOST = "https://geoip.elastic.dev"
    GEOIP_STAGING_ENDPOINT = "#{GEOIP_STAGING_HOST}#{LogStash::Filters::Geoip::DownloadManager::GEOIP_PATH}"

    before do
      allow(LogStash::SETTINGS).to receive(:get).with("xpack.geoip.download.endpoint").and_return(GEOIP_STAGING_ENDPOINT)
    end

    # this is disabled until https://github.com/elastic/logstash/issues/13261 is solved
    context "rest client" do

      it "can call endpoint" do
        conn = download_manager.send(:rest_client)
        res = conn.get("#{GEOIP_STAGING_ENDPOINT}?key=#{SecureRandom.uuid}&elastic_geoip_service_tos=agree")
        expect(res.code).to eq(200)
      end

      it "should raise error when endpoint response 4xx" do
        bad_uri = URI("#{GEOIP_STAGING_HOST}?key=#{SecureRandom.uuid}&elastic_geoip_service_tos=agree")
        expect(download_manager).to receive(:service_endpoint).and_return(bad_uri).twice
        expect { download_manager.send(:check_update) }.to raise_error(LogStash::Filters::Geoip::DownloadManager::BadResponseCodeError, /404/)
      end

      context "when ENV['http_proxy'] is set" do
        let(:mock_resp) { JSON.parse(::File.read(::File.expand_path("./fixtures/normal_resp.json", ::File.dirname(__FILE__)))) }
        let(:db_info) { mock_resp[1] }
        let(:proxy_url) { 'http://user:pass@example.com:1234' }

        around(:each) { |example| with_environment('http_proxy' => proxy_url, &example) }

        it "initializes the rest client with the proxy" do
          expect(::Manticore::Client).to receive(:new).with(a_hash_including(:proxy => proxy_url)).and_call_original

          download_manager.send(:rest_client)
        end

        it "download database with the proxy" do
          expect(download_manager).to receive(:md5).and_return(db_info['md5_hash'])
          expect(::Down).to receive(:download).with(db_info['url'], a_hash_including(:proxy => proxy_url)).and_return(true)

          download_manager.send(:download_database, database_type, second_dirname, db_info)
        end
      end
    end

    context "check update" do
      before(:each) do
        expect(download_manager).to receive(:uuid).and_return(SecureRandom.uuid)
        mock_resp = double("geoip_endpoint",
                           :body => ::File.read(::File.expand_path("./fixtures/normal_resp.json", ::File.dirname(__FILE__))),
                           :code => 200)
        allow(download_manager).to receive_message_chain("rest_client.get").and_return(mock_resp)
      end

      it "should return City db info when City md5 does not match" do
        expect(mock_metadata).to receive(:gz_md5).and_return("8d57aec1958070f01042ac1ecd8ec2ab", "a123a45d67890a2bd02e5edd680f6703c")

        updated_db = download_manager.send(:check_update)
        expect(updated_db.size).to eql(1)

        type, info = updated_db[0]
        expect(info).to have_key("md5_hash")
        expect(info).to have_key("name")
        expect(info).to have_key("provider")
        expect(info).to have_key("updated")
        expect(info).to have_key("url")
        expect(type).to eql(database_type)
      end

      it "should return empty array when md5 are the same" do
        expect(mock_metadata).to receive(:gz_md5).and_return("8d57aec1958070f01042ac1ecd8ec2ab", "a195a73d4651a2bd02e5edd680f6703c")

        updated_db = download_manager.send(:check_update)
        expect(updated_db.size).to eql(0)
      end

    end

    context "download database" do
      let(:db_info) do
        {
          "age" => 297221,
          "md5_hash" => md5_hash,
          "name" => filename,
          "provider" => "maxmind",
          "updated" => 1609891257,
          "url" => "https://github.com/logstash-plugins/logstash-filter-geoip/archive/main.zip"
        }
      end
      let(:md5_hash) { SecureRandom.hex }
      let(:filename) { "GeoLite2-City.tgz"}
      let(:dirname) { "0123456789" }

      it "should raise error if md5 does not match" do
        allow(Down).to receive(:download)
        expect{ download_manager.send(:download_database, database_type, dirname, db_info) }.to raise_error /wrong checksum/
      end

      it "should download file and return zip path" do
        expect(download_manager).to receive(:md5).and_return(md5_hash)

        new_zip_path = download_manager.send(:download_database, database_type, dirname, db_info)
        expect(new_zip_path).to match /GeoLite2-City\.tgz/
        expect(::File.exist?(new_zip_path)).to be_truthy
      end
    end

    context "unzip" do
      let(:dirname) { Time.now.to_i.to_s }
      let(:copyright_path) { get_file_path(dirname, 'COPYRIGHT.txt') }
      let(:license_path) { get_file_path(dirname, 'LICENSE.txt') }
      let(:readme_path) { get_file_path(dirname, 'README.txt') }
      let(:folder_path) { get_file_path(dirname, 'inner') }
      let(:folder_more_path) { ::File.join(folder_path, 'more.txt') }
      let(:folder_less_path) { ::File.join(folder_path, 'less.txt') }

      before do
        FileUtils.mkdir_p(get_dir_path(dirname))
      end

      after do
        file_path = ::File.expand_path("./fixtures/sample.mmdb", ::File.dirname(__FILE__))
        delete_file(file_path, copyright_path, license_path, readme_path)
        FileUtils.rm_r folder_path
      end

      it "should extract all files in tarball" do
        zip_path = ::File.expand_path("./fixtures/sample.tgz", ::File.dirname(__FILE__))
        new_db_path = download_manager.send(:unzip, database_type, dirname, zip_path)

        expect(new_db_path).to match /GeoLite2-#{database_type}\.mmdb/
        expect(::File.exist?(new_db_path)).to be_truthy
        expect(::File.exist?(copyright_path)).to be_truthy
        expect(::File.exist?(license_path)).to be_truthy
        expect(::File.exist?(readme_path)).to be_truthy
        expect(::File.directory?(folder_path)).to be_truthy
        expect(::File.exist?(folder_more_path)).to be_truthy
        expect(::File.exist?(folder_less_path)).to be_truthy
      end
    end

    context "assert database" do
      before do
        copy_cc(get_dir_path("CC"))
      end

      it "should raise error if file is invalid" do
        expect{ download_manager.send(:assert_database!, "Gemfile") }.to raise_error /failed to load database/
      end

      it "should pass validation" do
        expect(download_manager.send(:assert_database!, default_city_db_path)).to be_nil
      end
    end

    context "fetch database" do
      it "should return array of db which has valid download" do
        expect(download_manager).to receive(:check_update).and_return([[LogStash::Filters::Geoip::ASN, {}],
                                                                       [LogStash::Filters::Geoip::CITY, {}]])
        allow(download_manager).to receive(:download_database)
        allow(download_manager).to receive(:unzip).and_return("NEW_DATABASE_PATH")
        allow(download_manager).to receive(:assert_database!)

        updated_db = download_manager.send(:fetch_database)

        expect(updated_db.size).to eql(2)
        asn_type, asn_valid_download, asn_dirname, asn_path = updated_db[0]
        city_type, city_valid_download, city_dirname, city_path = updated_db[1]
        expect(asn_valid_download).to be_truthy
        expect(asn_path).to eql("NEW_DATABASE_PATH")
        expect(city_valid_download).to be_truthy
        expect(city_path).to eql("NEW_DATABASE_PATH")
      end

      it "should return array of db which has invalid download" do
        expect(download_manager).to receive(:check_update).and_return([[LogStash::Filters::Geoip::ASN, {}],
                                                                       [LogStash::Filters::Geoip::CITY, {}]])
        expect(download_manager).to receive(:download_database).and_raise('boom').at_least(:twice)

        updated_db = download_manager.send(:fetch_database)

        expect(updated_db.size).to eql(2)
        asn_type, asn_valid_download, asn_path = updated_db[0]
        city_type, city_valid_download, city_path = updated_db[1]
        expect(asn_valid_download).to be_falsey
        expect(asn_path).to be_nil
        expect(city_valid_download).to be_falsey
        expect(city_path).to be_nil
      end
    end

    context "download url" do
      before do
        allow(download_manager).to receive(:uuid).and_return(SecureRandom.uuid)
      end

      it "should give a path with hostname when input is a filename" do
        expect(download_manager.send(:download_url, "GeoLite2-ASN.tgz")).to match /#{GEOIP_STAGING_HOST}/
      end

      it "should give a unmodified path when input has scheme" do
        expect(download_manager.send(:download_url, GEOIP_STAGING_ENDPOINT)).to eq(GEOIP_STAGING_ENDPOINT)
      end
    end

    context "service endpoint" do
      before do
        allow(download_manager).to receive(:uuid).and_return(SecureRandom.uuid)
      end

      it "should give xpack setting" do
        uri = download_manager.send(:service_endpoint)
        expect(uri.to_s).to match /#{GEOIP_STAGING_ENDPOINT}/
      end

      context "empty xpack config" do
        before do
          allow(LogStash::SETTINGS).to receive(:get).with("xpack.geoip.download.endpoint").and_return(nil)
        end

        it "should give default endpoint" do
          uri = download_manager.send(:service_endpoint)
          expect(uri.to_s).to match /#{LogStash::Filters::Geoip::DownloadManager::GEOIP_ENDPOINT}/
        end
      end
    end
  end
end