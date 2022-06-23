# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# Patch to replace the usage of STDERR and STDOUT
# see: https://github.com/elastic/logstash/issues/5912
module LogStash
  class NullLogger
    def self.debug(message)
    end
  end

  # Despite {@link DelegatingLogWriter} Puma still uses log_writer.stderr
  # @private
  class IOWrappedLogger

    def initialize(log_writer)
      @log_writer = log_writer
    end

    def sync=(v)
      # noop
    end

    def sync
      # noop
    end

    def flush
      # noop
    end

    def puts(str)
      @log_writer.log(str)
    end
    alias_method :write, :puts
    alias_method :<<, :puts
  end

  # Replacement for Puma's `LogWriter` to redirect all logging to a logger.
  # @private
  class DelegatingLogWriter

    # NOTE: for env['rack.errors'] Puma does log_writer.stderr
    attr_reader :stdout, :stderr

    def initialize(logger)
      @logger = logger
      @stdout = @stderr = IOWrappedLogger.new(self)
    end

    # @overload
    def log(str)
      @logger.info(format(str))
    end

    # @overload
    def write(str)
      @logger.debug(str) # raw write - no formatting
    end

    # @overload
    def debug(str)
      @logger.debug? && @logger.debug(format(str))
    end

    # @overload
    def format(str)
      str.to_s # we do not want "[#{$$}] #{str}"
    end

    # An HTTP connection error has occurred.
    # +error+ a connection exception, +req+ the request,
    # and +text+ additional info
    # @overload
    def connection_error(error, req, text="HTTP connection error")
      @logger.error(text, error: error, request: req)
    end

    # An HTTP parse error has occurred.
    # +error+ a parsing exception, and +req+ the request.
    def parse_error(error, req)
      @logger.warn('HTTP parse error, malformed request', error: error, request: req)
    end

    # An SSL error has occurred.
    # @param error <Puma::MiniSSL::SSLError>
    # @param ssl_socket <Puma::MiniSSL::Socket>
    # @overload
    def ssl_error(error, ssl_socket)
      peer = ssl_socket.peeraddr.last rescue "<unknown>"
      peer_cert = ssl_socket.peercert&.subject
      @error_logger.info("SSL error", error: error, peer: peer, peer_cert: peer_cert)
    end

    # An unknown error has occurred.
    # +error+ an exception object, +req+ the request,
    # and +text+ additional info
    # @overload
    def unknown_error(error, req=nil, text="Unknown error")
      @logger.error(text, error: error, request: req)
    end

    # Log occurred error debug dump.
    # +error+ an exception object, +req+ the request,
    # and +text+ additional info
    # @overload
    def debug_error(error, req=nil, text="")
      @logger.debug(text, error: error, request: req)
    end

  end

  # ::Puma::Events#error(str) sends Kernel#exit
  # let's raise something sensible instead.
  # UnrecoverablePumaError = Class.new(RuntimeError)
  # TODO what is the new way Puma would exit on error?
  # class NonCrashingPumaEvents < ::Puma::Events
  #   def error(str)
  #     raise UnrecoverablePumaError.new(str)
  #   end
  # end
end

# JRuby (>= 9.2.18.0) added support for getsockopt(Socket::IPPROTO_TCP, Socket::TCP_INFO)
# however it isn't working correctly on ARM64 likely due an underlying issue in JNR/JFFI.
#
# Puma uses the TCP_INFO to detect a closed socket when handling a request and has a dummy
# fallback in place when Socket constants :TCP_INFO && :IPPROTO_TCP are not defined, see:
# https://github.com/puma/puma/blob/v5.5.2/lib/puma/server.rb#L169-L192
#
# Remove this patch once https://github.com/elastic/logstash/issues/13444 gets resolved!
if ENV_JAVA['os.name'].match?(/Linux/i) && ENV_JAVA['os.arch'].eql?('aarch64')
  Puma::Server.class_eval do
    def closed_socket?(socket)
      false
    end
  end
end
