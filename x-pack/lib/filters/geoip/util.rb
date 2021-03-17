# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "digest"


module LogStash module Filters
  module Geoip
    GZ_EXTENSION = 'tgz'.freeze
    DB_EXTENSION = 'mmdb'.freeze

    module Util
      def get_file_path(filename)
        ::File.join(@vendor_path, filename)
      end

      def file_exist?(path)
        !path.nil? && ::File.exist?(path) && !::File.empty?(path)
      end

      def md5(file_path)
        file_exist?(file_path) ? Digest::MD5.hexdigest(::File.read(file_path)): ""
      end

      def get_gz_name(filename)
        filename.sub(/(.*)\.#{DB_EXTENSION}/, "\\1.#{GZ_EXTENSION}")
      end

      def database_name_prefix
        @database_name_prefix ||= "GeoLite2-#{@database_type}"
      end

      def database_name
        @database_name ||= database_name_prefix + '.' + DB_EXTENSION
      end
    end
  end
end end