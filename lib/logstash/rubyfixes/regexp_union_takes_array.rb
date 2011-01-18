# Check if Regexp.union takes an array. If not, monkeypatch it.
# This feature was added in Ruby 1.8.7 and is required by 
# Rack 1.2.1, breaking ruby <= 1.8.6

needs_fix = false
begin
  Regexp.union(["a", "b"])
rescue TypeError => e
  if e.message == "can't convert Array into String"
    needs_fix = true
  end
end

if needs_fix
  class Regexp
    class << self
      alias_method :orig_regexp_union, :union
      public
      def union(*args)
        if args[0].is_a?(Array) && args.size == 1
          return orig_regexp_union(*args[0])
        end
        return orig_regexp_union(*args)
      end # def union
    end # class << self 
  end # class Regexp
end # if needs_fix
