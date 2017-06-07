# encoding: utf-8

module LogStash
  module StringInterpolation
    extend self

    # clear the global compiled templates cache
    def clear_cache
      Java::OrgLogstash::StringInterpolation.clear_cache;
    end

    # @return [Fixnum] the compiled templates cache size
    def cache_size
      Java::OrgLogstash::StringInterpolation.cache_size;
    end
  end
end

