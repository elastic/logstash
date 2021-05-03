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

  def initialize(metadata)
    @metadata = metadata
  end

  GEOIP_HOST = "https://geoip.elastic.co".freeze
  GEOIP_PATH = "/v1/database".freeze
  GEOIP_ENDPOINT = "#{GEOIP_HOST}#{GEOIP_PATH}".freeze

  public
  # Check available update and download them. Unzip and validate the file.
  # if the download failed, valid_download return false
  # return Array of new database path [database_type, valid_download, new_database_path]
  def fetch_database
    check_update
      .map do |database_type, db_info|
        begin
          new_database_path = unzip *download_database(database_type, db_info)
          assert_database!(new_database_path)
          [database_type, true, new_database_path]
        rescue
          [database_type, false, nil]
        end
      end
  end
  
  private
  # Call infra endpoint to get md5 of latest databases and verify with metadata
  # return Array of new database information [database_type, db_info]
  def check_update
    uuid = get_uuid
    res = rest_client.get("#{GEOIP_ENDPOINT}?key=#{uuid}&elastic_geoip_service_tos=agree")
    logger.debug("check update", :endpoint => GEOIP_ENDPOINT, :response => res.status)

    service_resp = JSON.parse(res.body)

    updated_db = DB_TYPES.map do |database_type|
      db_info = service_resp.select { |db| db['name'].eql?("#{GEOLITE}#{database_type}.#{GZ_EXT}") }.first
      has_update = @metadata.gz_md5(database_type) != db_info['md5_hash']
      [database_type, has_update, db_info]
    end
    .select { |database_type, has_update, db_info| has_update }
    .map { |database_type, has_update, db_info| [database_type, db_info] }

    logger.info "new database version detected? #{!updated_db.empty?}"

    updated_db
  end

  def download_database(database_type, db_info)
    Stud.try(3.times) do
      timestamp = Time.now.to_i
      new_database_zip_path = get_file_path("#{GEOLITE}#{database_type}_#{timestamp}.#{GZ_EXT}")
      Down.download(db_info['url'], destination: new_database_zip_path)
      raise "the new download has wrong checksum" if md5(new_database_zip_path) != db_info['md5_hash']

      logger.debug("new database downloaded in ", :path => new_database_zip_path)
      [database_type, timestamp, new_database_zip_path]
    end
  end

  # extract all files and folders from .tgz to path.data directory
  # existing files folders will be replaced
  def unzip(type, timestamp, zip_path)
    new_database_path = get_file_path("#{GEOLITE}#{type}_#{timestamp}.#{DB_EXT}")
    temp_dir = Stud::Temporary.pathname

    LogStash::Util::Tar.extract(zip_path, temp_dir)
    logger.debug("extract database to ", :path => temp_dir)

    ::Dir.each_child(temp_dir) do |file|
      path = ::File.join(temp_dir, file)

      if !::File.directory?(path) && "#{GEOLITE}#{type}.#{DB_EXT}".eql?(file)
        FileUtils.cp(path, new_database_path)
      else
        FileUtils.cp_r(path, get_data_dir)
      end
    end

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
