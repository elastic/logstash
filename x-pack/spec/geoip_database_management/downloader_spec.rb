# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

describe LogStash::GeoipDatabaseManagement::Downloader, aggregate_failures: true, verify_stubs: true do
  let(:temp_metadata_path) { Stud::Temporary.directory }
  let(:data_path) { LogStash::GeoipDatabaseManagement::DataPath.new(temp_metadata_path) }
  let(:metadata) { LogStash::GeoipDatabaseManagement::Metadata.new(data_path) }

  let(:service_host) { "https://geoip.elastic.dev" }
  let(:service_path) { "v1/database" }
  let(:service_endpoint) { "#{service_host}/#{service_path}" }

  let(:database_type) { constants::CITY }

  let(:constants) { LogStash::GeoipDatabaseManagement::Constants }

  subject(:downloader) { described_class.new(metadata, service_endpoint) }

  after(:each) do
    FileUtils::rm_rf(temp_metadata_path)
  end

  context "rest client" do
    it "can call endpoint" do
      conn = downloader.send(:rest_client)
      res = conn.get(downloader.list_databases_url)
      expect(res.code).to eq(200)
    end

    it 'raises error when endpoint response 4xx' do
      bad_uri = "#{service_host}/?key=#{SecureRandom.uuid}&elastic_geoip_service_tos=agree"
      expect(downloader).to receive(:list_databases_url).and_return(bad_uri).twice
      expect { downloader.send(:check_update, constants::DB_TYPES) }.to raise_error(described_class::BadResponseCodeError, /404/)
    end

    context "when ENV['http_proxy'] is set" do
      let(:mock_resp) { JSON.parse(::File.read(::File.expand_path("./fixtures/normal_resp.json", ::File.dirname(__FILE__)))) }
      let(:db_info) { mock_resp.find {|i| i["name"].include?(database_type) } }
      let(:proxy_url) { 'http://user:pass@example.com:1234' }

      around(:each) { |example| with_environment('http_proxy' => proxy_url, &example) }

      it "initializes the rest client with the proxy" do
        expect(::Manticore::Client).to receive(:new).with(a_hash_including(:proxy => proxy_url)).and_call_original

        downloader.send(:rest_client)
      end

      it "download database with the proxy" do
        dirname = Time.now.to_i.to_s
        expected_gz_download_location = data_path.gz(database_type, dirname)
        expect(downloader).to receive(:md5).with(expected_gz_download_location).and_return(db_info['md5_hash'])
        expect(::Down).to receive(:download).with(db_info['url'], a_hash_including(:proxy => proxy_url)).and_return(true)

        downloader.send(:download_database, database_type, dirname, db_info)
      end
    end
  end

  context 'check_update' do
    let(:mock_resp_decoded) { JSON.parse(mock_resp_body) }
    let(:mock_resp_body) { ::File.read(::File.expand_path("./fixtures/normal_resp.json", ::File.dirname(__FILE__))) }
    let(:mock_resp) { double("list_databases_response", :body => mock_resp_body, code: 200)}

    let(:asn_info) { mock_resp_decoded.find { |i| i["name"].include?(constants::ASN) } }
    let(:city_info) { mock_resp_decoded.find { |i| i["name"].include?(constants::CITY) } }

    before(:each) do
      allow(downloader).to receive_message_chain('rest_client.get').and_return(mock_resp)
    end

    it "returns City db info when City md5 does not match" do
      metadata_city_gzmd5 = SecureRandom.hex(20)
      expect(metadata).to receive(:database_path).with(constants::CITY).and_return("/this/that/GeoLite2-City.mmdb")
      expect(metadata).to receive(:gz_md5).with(constants::CITY).and_return(metadata_city_gzmd5)

      expect(metadata).to receive(:database_path).with(constants::ASN).and_return("/this/that/GeoLite2-ASN.mmdb")
      expect(metadata).to receive(:gz_md5).with(constants::ASN).and_return(asn_info['md5_hash'])

      updated_dbs = downloader.send(:check_update, constants::DB_TYPES)
      expect(updated_dbs.size).to eql(1)

      type, info = updated_dbs[0]
      expect(info).to have_key("md5_hash")
      expect(info).to have_key("name")
      expect(info).to have_key("provider")
      expect(info).to have_key("updated")
      expect(info).to have_key("url")
      expect(type).to eql(constants::CITY)
    end

    it "returns empty array when all md5's match" do
      expect(metadata).to receive(:database_path).with(constants::CITY).and_return("/this/that/GeoLite2-City.mmdb")
      expect(metadata).to receive(:gz_md5).with(constants::CITY).and_return(city_info['md5_hash'])

      expect(metadata).to receive(:database_path).with(constants::ASN).and_return("/this/that/GeoLite2-ASN.mmdb")
      expect(metadata).to receive(:gz_md5).with(constants::ASN).and_return(asn_info['md5_hash'])

      updated_dbs = downloader.send(:check_update, constants::DB_TYPES)
      expect(updated_dbs.size).to eql(0)
    end

    it "returns City db info when City db not in metadata" do
      expect(metadata).to receive(:database_path).with(constants::CITY).and_return(nil) # signal missing file

      expect(metadata).to receive(:database_path).with(constants::ASN).and_return("/this/that/GeoLite2-ASN.mmdb")
      expect(metadata).to receive(:gz_md5).with(constants::ASN).and_return(asn_info['md5_hash'])

      updated_dbs = downloader.send(:check_update, constants::DB_TYPES)
      expect(updated_dbs.size).to eql(1)

      type, info = updated_dbs[0]
      expect(info).to have_key("md5_hash")
      expect(info).to have_key("name")
      expect(info).to have_key("provider")
      expect(info).to have_key("updated")
      expect(info).to have_key("url")
      expect(type).to eql(constants::CITY)
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
        "url" => expected_download_url
      }
    end
    let(:md5_hash) { SecureRandom.hex }
    let(:filename) { "GeoLite2-City.tgz"}
    let(:dirname) { "0123456789" }

    let(:expected_download_url) { "#{service_host}/blob/sample.tgz" }
    let(:sample_city_db_gz) { ::File.expand_path("./fixtures/sample.tgz", ::File.dirname(__FILE__)) }

    before(:each) do
      allow(Down).to receive(:download).with(expected_download_url, anything) do |url, options|
        FileUtils::cp(sample_city_db_gz, options[:destination])
        true
      end
    end

    context "with mismatched md5 checksum" do
      let(:md5_hash) { SecureRandom.hex }
      it "should raise error if md5 does not match" do
        expect { downloader.send(:download_database, database_type, dirname, db_info) }.to raise_error /wrong checksum/
      end
    end

    context "with matching md5 checksum" do
      let(:md5_hash) { LogStash::GeoipDatabaseManagement::Util.md5(sample_city_db_gz) }
      it "should download file and return zip path" do
        new_zip_path = downloader.send(:download_database, database_type, dirname, db_info)
        expect(new_zip_path).to match /GeoLite2-City\.tgz/
        expect(::File.exist?(new_zip_path)).to be_truthy
      end
    end
  end

  context "unzip" do
    let(:dirname) { Time.now.to_i.to_s }
    let(:copyright_path) { data_path.resolve(dirname, 'COPYRIGHT.txt') }
    let(:license_path) { data_path.resolve(dirname, 'LICENSE.txt') }
    let(:readme_path) { data_path.resolve(dirname, 'README.txt') }
    let(:folder_path) { data_path.resolve(dirname, 'inner') }
    let(:folder_more_path) { data_path.resolve(dirname, 'inner', 'more.txt') }
    let(:folder_less_path) { data_path.resolve(dirname, 'inner', 'less.txt') }

    before do
      FileUtils.mkdir_p(data_path.resolve(dirname))
    end

    it "should extract all files in tarball" do
      zip_path = ::File.expand_path("./fixtures/sample.tgz", ::File.dirname(__FILE__))
      new_db_path = downloader.send(:unzip, database_type, dirname, zip_path)

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

  context "assert_database!" do

    let(:sample_city_db_gz) { ::File.expand_path("./fixtures/sample.tgz", ::File.dirname(__FILE__)) }

    it "rejects files that don't exist" do
      expect { downloader.send(:assert_database!, data_path.resolve("nope.mmdb") ) }.to raise_exception(/does not exist/)
    end
    it "rejects files that aren't MMDB" do
      expect { downloader.send(:assert_database!, __FILE__ ) }.to raise_exception(/does not appear to be a MaxMind DB/)
    end
    it "accepts files that have MMDB marker" do
      candidate = data_path.db(constants::CITY, "expanded")
      FileUtils.mkdir_p(data_path.resolve("expanded"))

      # A file that has the magic MaxMind marker buried inside it
      ::File.open(candidate, 'w:BINARY') do |handle|
        handle.write("#{database_type}".b)
        handle.write(SecureRandom.bytes(rand(2048...10240)).b)
        handle.write("#\xab\xcd\xefMaxMind.com".b)
        handle.write(SecureRandom.bytes(rand(2048...10240)).b)
        handle.write("#{database_type}".b)
        handle.flush
      end

      downloader.send(:assert_database!, candidate)
    end
  end

  context "fetch_databases" do
    it "should return array of db which has valid download" do
      expect(downloader).to receive(:check_update).and_return([[constants::ASN, {}],
                                                               [constants::CITY, {}]])
      allow(downloader).to receive(:download_database)
      allow(downloader).to receive(:unzip).and_return("NEW_DATABASE_PATH")
      expect(downloader).to receive(:assert_database!).at_least(:once)

      updated_db = downloader.send(:fetch_databases, constants::DB_TYPES)

      expect(updated_db.size).to eql(2)
      asn_type, asn_valid_download, asn_dirname, asn_path = updated_db[0]
      city_type, city_valid_download, city_dirname, city_path = updated_db[1]
      expect(asn_valid_download).to be_truthy
      expect(asn_path).to eql("NEW_DATABASE_PATH")
      expect(city_valid_download).to be_truthy
      expect(city_path).to eql("NEW_DATABASE_PATH")
    end

    it "should return array of db which has invalid download" do
      expect(downloader).to receive(:check_update).and_return([[constants::ASN, {}],
                                                               [constants::CITY, {}]])
      expect(downloader).to receive(:download_database).and_raise('boom').at_least(:twice)

      updated_db = downloader.send(:fetch_databases, constants::DB_TYPES)

      expect(updated_db.size).to eql(2)
      asn_type, asn_valid_download, asn_path = updated_db[0]
      city_type, city_valid_download, city_path = updated_db[1]
      expect(asn_valid_download).to be_falsey
      expect(asn_path).to be_nil
      expect(city_valid_download).to be_falsey
      expect(city_path).to be_nil
    end
  end

  context "#resolve_download_url" do
    context "when given an absolute URL" do
      let(:absolute_url) { "https://example.com/blob/this.tgz" }
      it 'returns the provided URL' do
        expect(downloader.send(:resolve_download_url, absolute_url).to_s).to eq(absolute_url)
      end
    end
    context "when given a relative URL with absolute path" do
      let(:relative_url) { "/blob/this.tgz" }
      it 'returns a url resolved relative to service endpoint' do
        expect(downloader.send(:resolve_download_url, relative_url).to_s).to eq("#{service_host}#{relative_url}")
      end
    end
    context "when given a relative URL with relative path" do
      let(:relative_url) { "blob/this.tgz" }
      it 'returns a url resolved relative to service endpoint' do
        expect(downloader.send(:resolve_download_url, relative_url).to_s).to eq("#{service_host}/v1/#{relative_url}")
      end
    end
  end

  context "#list_databases_url" do
    subject(:list_databases_url) { downloader.list_databases_url }
    it "adds the key and tos agreement parameters" do
      expect(list_databases_url.host).to eq("geoip.elastic.dev")
      expect(list_databases_url.path).to eq("/v1/database")
      expect(list_databases_url.query).to include "key=#{downloader.send(:uuid)}"
      expect(list_databases_url.query).to include "elastic_geoip_service_tos=agree"
    end
  end
end