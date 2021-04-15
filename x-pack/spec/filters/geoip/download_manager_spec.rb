# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative 'test_helper'
require 'fileutils'
require "filters/geoip/download_manager"

describe LogStash::Filters::Geoip do

  describe 'DownloadManager', :aggregate_failures do
    let(:mock_metadata)  { double("database_metadata") }
    let(:download_manager) do
      manager = LogStash::Filters::Geoip::DownloadManager.new( "City", mock_metadata, get_vendor_path)
      manager
    end
    let(:logger) { double("Logger") }

    GEOIP_STAGING_HOST = "https://geoip.elastic.dev"
    GEOIP_STAGING_ENDPOINT = "#{GEOIP_STAGING_HOST}#{LogStash::Filters::Geoip::DownloadManager::GEOIP_PATH}"

    before do
      stub_const('LogStash::Filters::Geoip::DownloadManager::GEOIP_ENDPOINT', GEOIP_STAGING_ENDPOINT)
    end

    context "rest client" do
      it "can call endpoint" do
        conn = download_manager.send(:rest_client)
        res = conn.get("#{GEOIP_STAGING_ENDPOINT}?key=#{SecureRandom.uuid}&elastic_geoip_service_tos=agree")
        expect(res.status).to eq(200)
      end

      it "should raise error when endpoint response 4xx" do
        conn = download_manager.send(:rest_client)
        expect { conn.get("#{GEOIP_STAGING_HOST}?key=#{SecureRandom.uuid}&elastic_geoip_service_tos=agree") }.to raise_error /404/
      end
    end

    context "check update" do
      before(:each) do
        expect(download_manager).to receive(:get_uuid).and_return(SecureRandom.uuid)
        mock_resp = double("geoip_endpoint",
                           :body => ::File.read(::File.expand_path("./fixtures/normal_resp.json", ::File.dirname(__FILE__))),
                           :status => 200)
        allow(download_manager).to receive_message_chain("rest_client.get").and_return(mock_resp)
      end

      it "should return has_update and db info when md5 does not match" do
        expect(mock_metadata).to receive(:gz_md5).and_return("")

        has_update, info = download_manager.send(:check_update)
        expect(has_update).to be_truthy
        expect(info).to have_key("md5_hash")
        expect(info).to have_key("name")
        expect(info).to have_key("provider")
        expect(info).to have_key("updated")
        expect(info).to have_key("url")
        expect(info["name"]).to include("City")
      end

      it "should return false when md5 is the same" do
        expect(mock_metadata).to receive(:gz_md5).and_return("89d225ac546310b1e7979502ac9ad11c")

        has_update, info = download_manager.send(:check_update)
        expect(has_update).to be_falsey
      end

      it "should return true when md5 does not match" do
        expect(mock_metadata).to receive(:gz_md5).and_return("bca2a8bad7e5e4013dc17343af52a841")

        has_update, info = download_manager.send(:check_update)
        expect(has_update).to be_truthy
      end
    end

    context "download database" do
      let(:db_info) do
        {
          "md5_hash" => md5_hash,
          "name" => filename,
          "provider" => "maxmind",
          "updated" => 1609891257,
          "url" => "https://github.com/logstash-plugins/logstash-filter-geoip/archive/master.zip"
        }
      end
      let(:md5_hash) { SecureRandom.hex }
      let(:filename) { "GeoLite2-City.tgz"}

      it "should raise error if md5 does not match" do
        allow(Down).to receive(:download)
        expect{ download_manager.send(:download_database, db_info) }.to raise_error /wrong checksum/
      end

      it "should download file and return zip path" do
        expect(download_manager).to receive(:md5).and_return(md5_hash)

        path = download_manager.send(:download_database, db_info)
        expect(path).to match /GeoLite2-City_\d+\.tgz/
        expect(::File.exist?(path)).to be_truthy

        delete_file(path)
      end
    end

    context "unzip" do
      let(:copyright_path) { get_file_path('COPYRIGHT.txt') }
      let(:license_path) { get_file_path('LICENSE.txt') }
      let(:readme_path) { get_file_path('README.txt') }
      let(:folder_path) { get_file_path('inner') }
      let(:folder_more_path) { ::File.join(get_file_path('inner'), 'more.txt') }
      let(:folder_less_path) { ::File.join(get_file_path('inner'), 'less.txt') }

      after do
        file_path = ::File.expand_path("./fixtures/sample.mmdb", ::File.dirname(__FILE__))
        delete_file(file_path, copyright_path, license_path, readme_path)
        FileUtils.rm_r folder_path
      end

      it "should extract all files in tarball" do
        path = ::File.expand_path("./fixtures/sample.tgz", ::File.dirname(__FILE__))
        unzip_db_path = download_manager.send(:unzip, path)

        expect(unzip_db_path).to match /\.mmdb/
        expect(::File.exist?(unzip_db_path)).to be_truthy
        expect(::File.exist?(copyright_path)).to be_truthy
        expect(::File.exist?(license_path)).to be_truthy
        expect(::File.exist?(readme_path)).to be_truthy
        expect(::File.directory?(folder_path)).to be_truthy
        expect(::File.exist?(folder_more_path)).to be_truthy
        expect(::File.exist?(folder_less_path)).to be_truthy
      end
    end

    context "assert database" do
      it "should raise error if file is invalid" do
        expect{ download_manager.send(:assert_database!, "Gemfile") }.to raise_error /failed to load database/
      end

      it "should pass validation" do
        expect(download_manager.send(:assert_database!, default_city_db_path)).to be_nil
      end
    end

    context "fetch database" do
      it "should be false if no update" do
        expect(download_manager).to receive(:check_update).and_return([false, {}])

        has_update, new_database_path = download_manager.send(:fetch_database)

        expect(has_update).to be_falsey
        expect(new_database_path).to be_nil
      end

      it "should raise error" do
        expect(download_manager).to receive(:check_update).and_return([true, {}])
        expect(download_manager).to receive(:download_database).and_raise('boom')

        expect { download_manager.send(:fetch_database) }.to raise_error
      end

      it "should be true if got update" do
        expect(download_manager).to receive(:check_update).and_return([true, {}])
        allow(download_manager).to receive(:download_database)
        allow(download_manager).to receive(:unzip)
        allow(download_manager).to receive(:assert_database!)

        has_update, new_database_path = download_manager.send(:fetch_database)

        expect(has_update).to be_truthy
      end
    end

  end
end