# encoding: utf-8

module LogStash
  module StringInterpolation
    extend self

    # clear the global compiled templates cache
    def clear_cache
      Java::OrgLogstash::StringInterpolation.get_instance.clear_cache;
    end

    # @return [Fixnum] the compiled templates cache size
    def cache_size
      Java::OrgLogstash::StringInterpolation.get_instance.cache_size;
    end
  end
end

