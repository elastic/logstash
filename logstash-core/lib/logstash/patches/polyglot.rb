# NOTE: this patch is meant to be used when polyglot (a tree-top dependency) is loaded.
# At runtime we avoid loading polyglot, it's only needed for the rake compile task atm.
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
