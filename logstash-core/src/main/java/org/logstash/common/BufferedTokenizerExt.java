package org.logstash.common;

import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

@JRubyClass(name = "BufferedTokenizer")
public class BufferedTokenizerExt extends RubyObject {

    private static final IRubyObject MINUS_ONE = RubyUtil.RUBY.newFixnum(-1);

    private RubyArray input = RubyUtil.RUBY.newArray();
    private IRubyObject delimiter = RubyUtil.RUBY.newString("\n");
    private int sizeLimit;
    private boolean hasSizeLimit;
    private int inputSize;

    public BufferedTokenizerExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "initialize", optional = 2)
    public IRubyObject init(final ThreadContext context, IRubyObject[] args) {
        if (args.length >= 1) {
            this.delimiter = args[0];
        }
        if (args.length == 2) {
            this.sizeLimit = args[1].convertToInteger().getIntValue();
            this.hasSizeLimit = true;
        }
        this.inputSize = 0;
        return this;
    }

    /**
     * Extract takes an arbitrary string of input data and returns an array of
     * tokenized entities, provided there were any available to extract.  This
     * makes for easy processing of datagrams using a pattern like:
     *
     * {@code tokenizer.extract(data).map { |entity| Decode(entity) }.each do}
     *
     * @param context ThreadContext
     * @param data    IRubyObject
     * @return Extracted tokens
     */
    @JRubyMethod
    public RubyArray extract(final ThreadContext context, IRubyObject data) {
        final RubyArray entities = ((RubyString) data).split(context, delimiter, MINUS_ONE);
        if (hasSizeLimit) {
            final int entitiesSize = ((RubyString) entities.first()).size();
            if (inputSize + entitiesSize > sizeLimit) {
                throw new IllegalStateException("input buffer full");
            }
            this.inputSize = inputSize + entitiesSize;
        }
        input.append(entities.shift(context));
        if (entities.isEmpty()) {
            return RubyUtil.RUBY.newArray();
        }
        entities.unshift(input.join(context));
        input.clear();
        input.append(entities.pop(context));
        inputSize = ((RubyString) input.first()).size();
        return entities;
    }

    /**
     * Flush the contents of the input buffer, i.e. return the input buffer even though
     * a token has not yet been encountered
     *
     * @param context ThreadContext
     * @return Buffer contents
     */
    @JRubyMethod
    public IRubyObject flush(final ThreadContext context) {
        final IRubyObject buffer = input.join(context);
        input.clear();
        return buffer;
    }

    @JRubyMethod(name = "empty?")
    public IRubyObject isEmpty(final ThreadContext context) {
        return input.empty_p();
    }

}
