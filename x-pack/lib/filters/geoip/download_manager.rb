# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require_relative "util"
require_relative "database_metadata"
require "logstash-filter-geoip_jars"
require "faraday"
require "json"
require "zlib"
require "stud/try"
require "down"

module LogStash module Filters module Geoip class DownloadManager
  include LogStash::Util::Loggable
  include LogStash::Filters::Geoip::Util

  def initialize(database_type, metadata, vendor_path)
    @vendor_path = vendor_path
    @database_type = database_type
    @metadata = metadata
  end

  GEOIP_HOST = "https://paisano.elastic.dev".freeze
  GEOIP_ENDPOINT = "#{GEOIP_HOST}/v1/geoip/database/".freeze

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

  private
  # Call infra endpoint to get md5 of latest database and verify with metadata
  # return [has_update, server db info]
  def check_update
    uuid = get_uuid
    res = rest_client.get("#{GEOIP_ENDPOINT}?key=#{uuid}&elastic_geoip_service_tos=agree")
    logger.info "#{GEOIP_ENDPOINT} return #{res.status}"

    all_db = JSON.parse(res.body)
    target_db = all_db.select { |info| info['name'].include?(@database_type) }.first

    [@metadata.gz_md5 != target_db['md5_hash'], target_db]
  end

  def download_database(server_db)
    Stud.try(3.times) do
      new_database_zip_path = get_file_path("GeoLite2-#{@database_type}_#{Time.now.to_i}.mmdb.gz")
      Down.download(server_db['url'], destination: new_database_zip_path)
      raise "the new download has wrong checksum" if md5(new_database_zip_path) != server_db['md5_hash']

      logger.debug("new database downloaded in #{new_database_zip_path}")
      new_database_zip_path
    end
  end

  def unzip(zip_path)
    database_path = zip_path[0...-3]
    Zlib::GzipReader.open(zip_path) do |gz|
      ::File.open(database_path, "wb") do |f|
        f.print gz.read
      end
    end
    database_path
  end

  # Make sure the path has usable database
  def assert_database!(database_path)
    raise "failed to load database #{database_path}" unless org.logstash.filters.GeoIPFilter.database_valid?(database_path)
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
