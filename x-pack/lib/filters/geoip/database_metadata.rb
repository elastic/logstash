# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require_relative "util"
require "csv"
require "date"

module LogStash module Filters module Geoip class DatabaseMetadata
  include LogStash::Util::Loggable
  include LogStash::Filters::Geoip::Util

  def initialize
    @metadata_path = get_file_path("metadata.csv")
  end

  public

  # csv format: database_type, update_at, gz_md5, md5, filename, is_eula
  def save_timestamp_database_path(database_type, database_path, is_eula)
    metadata = get_metadata(database_type, false)
    metadata << [database_type, Time.now.to_i, md5(get_gz_name(database_path)), md5(database_path),
                 ::File.basename(database_path), is_eula]
    update(metadata)
  end

  def update_timestamp(database_type)
    metadata = get_all.map do |row|
      row[Column::UPDATE_AT] = Time.now.to_i  if row[Column::DATABASE_TYPE].eql?(database_type)
      row
    end
    update(metadata)
  end

  def update(metadata)
    metadata.sort_by { |row| row[Column::DATABASE_TYPE] }
    ::CSV.open @metadata_path, 'w' do |csv|
      metadata.each { |row| csv << row }
    end
    logger.debug("metadata updated", :metadata => metadata)
  end

  def get_all
    file_exist?(@metadata_path)? ::CSV.read(@metadata_path, headers: false) : Array.new
  end

  # Give rows of metadata in default database type, or empty array
  def get_metadata(database_type, match = true)
    get_all.select { |row| row[Column::DATABASE_TYPE].eql?(database_type) == match }
  end

  # Return database path which has valid md5
  def database_path(database_type)
    get_metadata(database_type).map { |metadata| [metadata, get_file_path(metadata[Column::FILENAME])] }
                .select { |metadata, path| file_exist?(path) && (md5(path) == metadata[Column::MD5]) }
                .map { |metadata, path| path }
                .last
  end

  def gz_md5(database_type)
    get_metadata(database_type).map { |metadata| metadata[Column::GZ_MD5] }
                .last || ''
  end

  def updated_at(database_type)
    (get_metadata(database_type).map { |metadata| metadata[Column::UPDATE_AT] }
                 .last || 0).to_i
  end

  def is_eula(database_type)
    (get_metadata(database_type).map { |metadata| metadata[Column::IS_EULA] }
                 .last || 'false') == 'true'
  end

  # Return database related filenames in .mmdb .tgz
  def database_filenames
    get_all.flat_map { |metadata| [ metadata[Column::FILENAME], get_gz_name(metadata[Column::FILENAME]) ] }
  end
  
  def exist?
    file_exist?(@metadata_path)
  end

  class Column
    DATABASE_TYPE = 0
    UPDATE_AT     = 1
    GZ_MD5        = 2
    MD5           = 3
    FILENAME      = 4
    IS_EULA       = 5
  end

end end end end