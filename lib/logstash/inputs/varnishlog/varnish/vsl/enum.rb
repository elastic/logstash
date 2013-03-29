require 'logstash/inputs/varnishlog/varnish'
require 'ffi'

module Varnish
  module VSL
    module Enum
      extend FFI::Library

      VslTag = enum(
        :debug,
        :error,
        :cli,
        :statsess,
        :reqend,
        :sessionopen,
        :sessionclose,
        :backendopen,
        :backendxid,
        :backendreuse,
        :backendclose,
        :httpgarbage,
        :backend,
        :length,

        :fetcherror,

        :rxrequest,
        :rxresponse,
        :rxstatus,
        :rxurl,
        :rxprotocol,
        :rxheader,

        :txrequest,
        :txresponse,
        :txstatus,
        :txurl,
        :txprotocol,
        :txheader,

        :objrequest,
        :objresponse,
        :objstatus,
        :objurl,
        :objprotocol,
        :objheader,

        :lostheader,

        :ttl,
        :fetch_body,
        :vcl_acl,
        :vcl_call,
        :vcl_trace,
        :vcl_return,
        :vcl_error,
        :reqstart,
        :hit,
        :hitpass,
        :expban,
        :expkill,
        :workthread,

        :esi_xmlerror,

        :hash,

        :backend_health,
        :vcl_log,

        :gzip
      )
    end
  end
end
