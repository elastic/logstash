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

  # Puma still uses the STDERR an the STDOUT for a few error
  # handling, the server class accept custom a log writer object that can accept custom io object,
  # so it just wrap the logger into an IO like object.
  class IOWrappedLogger < ::Puma::NullIO
    def initialize(new_logger)
      @logger_lock = Mutex.new
      @logger = new_logger
    end

    def logger=(logger)
      @logger_lock.synchronize { @logger = logger }
    end

    # @overload
    def puts(str)
      return unless @logger.debug?
      # The logger only accept a str as the first argument
      @logger_lock.synchronize { @logger.debug(str.to_s) }
    end
    alias_method :write, :puts
    alias_method :<<, :puts
  end

  # ::Puma::LogWriter#error(str) sends Kernel#exit
  # This error will be raised instead.
  UnrecoverablePumaError = Class.new(RuntimeError)

  # Replacement for Puma's `LogWriter` to redirect all logging to a logger.
  # @private
  class DelegatingLogWriter
    attr_reader :stdout, :stderr

    def initialize(logger)
      @logger = logger
      @stdout = @stderr = IOWrappedLogger.new(self)
    end

    # @overload
    def write(str)
      # raw write - no formatting
      @logger.debug(str) if @logger.debug?
    end

    # @overload
    def debug(str)
      @logger.debug(format(str)) if @logger.debug?
    end
    alias_method :log, :debug

    # @overload
    def error(str)
      @logger.error(format(str))
      raise UnrecoverablePumaError.new(str)
    end

    # @overload
    def format(str)
      str.to_s
    end

    # An HTTP connection error has occurred.
    # +error+ a connection exception, +req+ the request,
    # and +text+ additional info
    # @version 5.0.0
    # @overload
    def connection_error(error, req, text = "HTTP connection error")
      @logger.debug(text, { error: error, req: req, backtrace: error&.backtrace }) if @logger.debug?
    end

    # An HTTP parse error has occurred.
    # +error+ a parsing exception, and +req+ the request.
    def parse_error(error, req)
      @logger.debug('HTTP parse error, malformed request', { error: error, req: req }) if @logger.debug?
    end

    # An SSL error has occurred.
    # @param error <Puma::MiniSSL::SSLError>
    # @param ssl_socket <Puma::MiniSSL::Socket>
    # @overload
    def ssl_error(error, ssl_socket)
      return unless @logger.debug?
      peeraddr = ssl_socket.peeraddr.last rescue "<unknown>"
      subject = ssl_socket.peercert&.subject
      @logger.debug("SSL error, peer: #{peeraddr}, peer cert: #{subject}", error: error)
    end

    # An unknown error has occurred.
    # +error+ an exception object, +req+ the request,
    # and +text+ additional info
    # @overload
    def unknown_error(error, req = nil, text = "Unknown error")
      details = { error: error, req: req }
      details[:backtrace] = error.backtrace if @logger.debug?
      @logger.error(text, details)
    end

    # Log occurred error debug dump.
    # +error+ an exception object, +req+ the request,
    # and +text+ additional info
    # @overload
    def debug_error(error, req = nil, text = "")
      @logger.debug(text, { error: error, req: req, backtrace: error&.backtrace }) if @logger.debug?
    end

    def debug?
      @logger.debug?
    end
  end
end

# Reopen the puma class to create a scoped STDERR and STDOUT
# This operation is thread safe since its done at the class level
# and force JRUBY to flush his classes cache.
module Puma
  STDERR = LogStash::IOWrappedLogger.new(LogStash::NullLogger)
  STDOUT = LogStash::IOWrappedLogger.new(LogStash::NullLogger)
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
