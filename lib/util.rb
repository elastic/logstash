module LogStash
  class Util
    def self.collapse(hash)
      hash.each do |k, v|
        if v.is_a?(Hash)
          hash.delete(k)
          collapse(v).each do |k2, v2|
            hash["#{k}/#{k2}"] = v2
          end
        elsif v.is_a?(Array)
          # do nothing; ferret can handle this
        elsif not v.is_a?(String)
          hash[k] = v.to_s
        end
      end
      return hash
    end
  end
end
