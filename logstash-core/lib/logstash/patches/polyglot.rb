require 'polyglot'


module Kernel
  alias original_require require

  def require(*a, &b)
    begin
      original_require(*a, &b)
    rescue RuntimeError => e
      # https://github.com/jruby/jruby/pull/7145 introduced an exception check for circular causes, which
      # breaks when the polyglot library is used and LoadErrors are emitted
      if e.message == "circular causes"
        raise e.cause
      end
      raise e
    end
  end
end
