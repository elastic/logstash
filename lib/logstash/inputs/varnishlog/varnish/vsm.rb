require 'logstash/inputs/varnishlog/varnish'
require 'ffi'

module Varnish
  module VSM
    extend FFI::Library
    ffi_lib Varnish::LIBVARNISHAPI

    attach_function 'VSM_New', [], :pointer
  end
end
