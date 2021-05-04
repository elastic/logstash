# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "digest"


module LogStash module Filters
  module Geoip
    GZ_EXT = 'tgz'.freeze
    DB_EXT = 'mmdb'.freeze
    GEOLITE = 'GeoLite2-'.freeze
    CITY = "City".freeze
    ASN = "ASN".freeze
    DB_TYPES = [ASN, CITY].freeze
    CITY_DB_NAME = "#{GEOLITE}#{CITY}.#{DB_EXT}".freeze
    ASN_DB_NAME = "#{GEOLITE}#{ASN}.#{DB_EXT}".freeze
    DEFAULT_DB_NAMES = [CITY_DB_NAME, ASN_DB_NAME].freeze

    module Util
      def get_file_path(filename)
        ::File.join(get_data_dir, filename)
      end

      def get_data_dir
        ::File.join(LogStash::SETTINGS.get_value("path.data"), "plugins", "filters", "geoip")
      end

      def file_exist?(path)
        !path.nil? && ::File.exist?(path) && !::File.empty?(path)
      end

      def md5(file_path)
        file_exist?(file_path) ? Digest::MD5.hexdigest(::File.read(file_path)): ""
      end

      # replace *.mmdb to *.tgz
      def get_gz_name(filename)
        filename[0...-(DB_EXT.length)] + GZ_EXT
      end
    end
  end
end end