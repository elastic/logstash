# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative '../../../lib/bootstrap/util/compress'
require 'logstash/util/loggable'

require_relative 'util'
require_relative 'metadata'

require "json"
require "zlib"
require "stud/try"
require "down"
require "fileutils"
require 'uri'

module LogStash module GeoipDatabaseManagement
  class Downloader
    include GeoipDatabaseManagement::Constants
    include GeoipDatabaseManagement::Util
    include LogStash::Util::Loggable

    class BadResponseCodeError < Error
      attr_reader :response_code, :response_body

      def initialize(response_code, response_body)
        @response_code = response_code
        @response_body = response_body
      end

      def message
        "GeoIP service response code '#{response_code}', body '#{response_body}'"
      end
    end

    attr_reader :list_databases_url

    ##
    # @param metadata [Metadata]
    # @param service_endpoint [URI,String]
    def initialize(metadata, service_endpoint)
      logger.trace("init", metadata: metadata, endpoint: service_endpoint)
      @metadata = metadata
      @paths = metadata.paths
      service_endpoint = URI(service_endpoint).dup.freeze

      if service_endpoint.query&.chars&.any?
        logger.warn("GeoIP endpoint URI includes query parameter, which will be ignored: `#{safe_uri service_endpoint}`")
      end

      @list_databases_url = service_endpoint.merge("?key=#{uuid}&elastic_geoip_service_tos=agree").freeze
    end

    public
    # Check available update and download them. Unzip and validate the file.
    # if the download failed, valid_download return false
    # return Array of [database_type, valid_download, dirname, new_database_path]
    def fetch_databases(db_types)
      dirname = Time.now.to_i.to_s
      check_update(db_types)
        .map do |database_type, db_info|
        begin
          new_zip_path = download_database(database_type, dirname, db_info)
          new_database_path = unzip(database_type, dirname, new_zip_path)
          assert_database!(new_database_path)
          [database_type, true, dirname, new_database_path]
        rescue => e
          logger.error("failed to fetch #{database_type} database", error_details(e, logger))
          [database_type, false, nil, nil]
        end
      end
    end

    private
    # Call infra endpoint to get md5 of latest databases and verify with metadata
    # return Array of new database information [database_type, db_info]
    def check_update(db_types)
      return enum_for(:check_update, db_types).to_a unless block_given?

      res = rest_client.get(list_databases_url)
      logger.debug("check update", :endpoint => safe_uri(list_databases_url).to_s, :response => res.code)

      if res.code < 200 || res.code > 299
        raise BadResponseCodeError.new(res.code, res.body)
      end

      service_resp = JSON.parse(res.body)

      db_types.each do |database_type|
        db_info = service_resp.find { |db| db['name'].eql?("#{GEOLITE}#{database_type}.#{GZ_EXT}") }
        if db_info.nil?
          logger.debug("Database service did not include #{database_type}")
        elsif @metadata.database_path(database_type).nil?
          logger.debug("Local #{database_type} database is not present.")
          yield(database_type, db_info)
        elsif @metadata.gz_md5(database_type) == db_info['md5_hash']
          logger.debug("Local #{database_type} database is up-to-date.")
        else
          logger.debug("Updated #{database_type} database is available.")
          yield(database_type, db_info)
        end
      end
    end

    def download_database(database_type, dirname, db_info)
      Stud.try(3.times) do
        FileUtils.mkdir_p(@paths.resolve(dirname))
        zip_path = @paths.gz(database_type, dirname)

        actual_url = resolve_download_url(db_info['url']).to_s
        logger.debug? && logger.debug("download #{actual_url}")

        options = { destination: zip_path }
        options.merge!({proxy: ENV['http_proxy']}) if ENV.include?('http_proxy')
        Down.download(actual_url, **options)

        raise "the new download has wrong checksum" if md5(zip_path) != db_info['md5_hash']

        logger.debug("new database downloaded in ", :path => zip_path)
        zip_path
      end
    end

    # extract all files and folders from .tgz to path.data directory
    # return dirname [String], new_database_path [String]
    def unzip(database_type, dirname, zip_path)
      temp_path = ::File.join(@paths.resolve(dirname), database_type)
      LogStash::Util::Tar.extract(zip_path, temp_path)
      FileUtils.cp_r(::File.join(temp_path, '.'), @paths.resolve(dirname))
      FileUtils.rm_r(temp_path)

      @paths.db(database_type, dirname)
    end

    def rest_client
      @client ||= begin
                    client_options = {
                      request_timeout: 15,
                      connect_timeout: 5
                    }
                    client_options[:proxy] = ENV['http_proxy'] if ENV.include?('http_proxy')
                    Manticore::Client.new(client_options)
                  end
    end

    def uuid
      @uuid ||= ::File.read(::File.join(LogStash::SETTINGS.get("path.data"), "uuid"))
    rescue
      "UNSET"
    end

    def resolve_download_url(possibly_relative_url)
      list_databases_url.merge(possibly_relative_url)
    end

    def assert_database!(database_path)
      raise "failed to load database #{database_path} because it does not exist" unless file_exist?(database_path)
      raise "failed to load database #{database_path} because it does not appear to be a MaxMind DB" unless scan_binary_file(database_path, "\xab\xcd\xefMaxMind.com")
    end

    def safe_uri(unsafe)
      LogStash::Util::SafeURI.new(unsafe)
    end

    ##
    # Scans a binary file for the given verbatim byte sequence
    # without loading the entire binary file into memory by scanning
    # in chunks
    def scan_binary_file(file_path, byte_sequence)
      byte_sequence = byte_sequence.b
      partial_size = [byte_sequence.bytesize, 1024].max
      ::File.open(file_path, 'r:BINARY') do |io|
        a, b = ''.b, ''.b # two binary buffers
        until io.eof?
          io.readpartial(partial_size, b)

          bridged_chunk = (a+b)

          return true if bridged_chunk.include?(byte_sequence)
          a,b = b,a # swap buffers before continuing
        end
      end

      false
    end
  end
end end
