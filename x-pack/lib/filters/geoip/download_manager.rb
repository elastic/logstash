# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative '../../../../lib/bootstrap/util/compress'
require "logstash/util/loggable"
require_relative "util"
require_relative "database_metadata"
require "logstash-filter-geoip_jars"
require "faraday"
require "json"
require "zlib"
require "stud/try"
require "down"
require "fileutils"

module LogStash module Filters module Geoip class DownloadManager
  include LogStash::Util::Loggable
  include LogStash::Filters::Geoip::Util

  def initialize(database_type, metadata, vendor_path)
    @vendor_path = vendor_path
    @database_type = database_type
    @metadata = metadata
  end

  GEOIP_HOST = "https://geoip.elastic.co".freeze
  GEOIP_PATH = "/v1/database".freeze
  GEOIP_ENDPOINT = "#{GEOIP_HOST}#{GEOIP_PATH}".freeze

  public
  # Check available update and download it. Unzip and validate the file.
  # return [has_update, new_database_path]
  def fetch_database
    has_update, database_info = check_update

    if has_update
      new_database_path = unzip download_database(database_info)
      assert_database!(new_database_path)
      return [true, new_database_path]
    end

    [false, nil]
  end

  def database_name
    @database_name ||= "#{DB_PREFIX}#{@database_type}"
  end

  def database_name_ext
    @database_name_ext ||= "#{database_name}.#{DB_EXT}"
  end
  
  private
  # Call infra endpoint to get md5 of latest database and verify with metadata
  # return [has_update, server db info]
  def check_update
    uuid = get_uuid
    res = rest_client.get("#{GEOIP_ENDPOINT}?key=#{uuid}&elastic_geoip_service_tos=agree")
    logger.debug("check update", :endpoint => GEOIP_ENDPOINT, :response => res.status)

    dbs = JSON.parse(res.body)
    target_db = dbs.select { |db| db['name'].eql?("#{database_name}.#{GZ_EXT}") }.first
    has_update = @metadata.gz_md5 != target_db['md5_hash']
    logger.info "new database version detected? #{has_update}"

    [has_update, target_db]
  end

  def download_database(server_db)
    Stud.try(3.times) do
      new_database_zip_path = get_file_path("#{database_name}_#{Time.now.to_i}.#{GZ_EXT}")
      Down.download(server_db['url'], destination: new_database_zip_path)
      raise "the new download has wrong checksum" if md5(new_database_zip_path) != server_db['md5_hash']

      logger.debug("new database downloaded in ", :path => new_database_zip_path)
      new_database_zip_path
    end
  end

  # extract COPYRIGHT.txt, LICENSE.txt and GeoLite2-{ASN,City}.mmdb from .tgz to temp directory
  def unzip(zip_path)
    new_database_path = zip_path[0...-(GZ_EXT.length)] + DB_EXT
    temp_dir = Stud::Temporary.pathname

    LogStash::Util::Tar.extract(zip_path, temp_dir)
    logger.debug("extract database to ", :path => temp_dir)


    FileUtils.cp(::File.join(temp_dir, database_name_ext), new_database_path)
    FileUtils.cp_r(::Dir.glob(::File.join(temp_dir, "{COPYRIGHT,LICENSE}.txt")), @vendor_path)

    new_database_path
  end

  # Make sure the path has usable database
  def assert_database!(database_path)
    raise "failed to load database #{database_path}" unless org.logstash.filters.geoip.GeoIPFilter.database_valid?(database_path)
  end

  def rest_client
    @client ||= Faraday.new do |conn|
      conn.use Faraday::Response::RaiseError
      conn.adapter :net_http
    end
  end

  def get_uuid
    @uuid ||= ::File.read(::File.join(LogStash::SETTINGS.get("path.data"), "uuid"))
  end
end end end end
