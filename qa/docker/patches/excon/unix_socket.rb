# frozen_string_literal: true

module Excon
  class UnixSocket < Excon::Socket
    private
    def connect
      @socket = ::UNIXSocket.new(@data[:socket])
    end
  end
end
