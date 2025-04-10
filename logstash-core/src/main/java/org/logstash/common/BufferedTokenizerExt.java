/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.common;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyEncoding;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.util.ByteList;
import org.logstash.RubyUtil;

import java.nio.charset.Charset;
import java.util.Iterator;

@JRubyClass(name = "BufferedTokenizer")
public class BufferedTokenizerExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    private String encodingName;
    private transient BufferedTokenizer tokenizer;

    public BufferedTokenizerExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "initialize", optional = 2)
    public IRubyObject init(final ThreadContext context, IRubyObject[] args) {
        String delimiter = "\n";
        if (args.length >= 1) {
            delimiter = args[0].convertToString().asJavaString();
        }
        if (args.length == 2) {
            final int sizeLimit = args[1].convertToInteger().getIntValue();
            this.tokenizer = new BufferedTokenizer(delimiter, sizeLimit);
        } else {
            this.tokenizer = new BufferedTokenizer(delimiter);
        }

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
    @SuppressWarnings("rawtypes")
    public IRubyObject extract(final ThreadContext context, IRubyObject data) {
        RubyEncoding encoding = (RubyEncoding) data.convertToString().encoding(context);
        encodingName = encoding.getEncoding().getCharsetName();

        Iterable<String> extractor = tokenizer.extract(data.asJavaString());

        // return an iterator that does the encoding conversion
        Iterator<CharSequence> rubyStringAdpaterIterator = new BufferedTokenizer.IteratorDecorator<>(extractor.iterator()) {
            @Override
            public CharSequence next() {
                return toEncodedRubyString(context, iterator.next());
            }
        };

        return RubyUtil.toRubyObject(new IterableAdapterWithEmptyCheck(rubyStringAdpaterIterator));
    }

    // Iterator to Iterable adapter with addition of isEmpty method
    public static class IterableAdapterWithEmptyCheck implements Iterable<CharSequence> {
        private final Iterator<CharSequence> origIterator;

        public IterableAdapterWithEmptyCheck(Iterator<CharSequence> origIterator) {
            this.origIterator = origIterator;
        }

        @Override
        public Iterator<CharSequence> iterator() {
            return origIterator;
        }

        public boolean isEmpty() {
            return !origIterator.hasNext();
        }
    }

    private RubyString toEncodedRubyString(ThreadContext context, String input) {
        // Depends on the encodingName being set by the extract method, could potentially raise if not set.
        RubyString result = RubyUtil.RUBY.newString(new ByteList(input.getBytes(Charset.forName(encodingName))));
        result.force_encoding(context, RubyUtil.RUBY.newString(encodingName));
        return result;
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
        String s = tokenizer.flush();

        // create new RubyString with the last data specified encoding, if exists
        if (encodingName != null) {
            return toEncodedRubyString(context, s);
        } else {
            // When used with TCP input it could be that on socket connection the flush method
            // is invoked while no invocation of extract, leaving the encoding name unassigned.
            // In such case also the headToken must be empty
            if (!s.isEmpty()) {
                throw new IllegalStateException("invoked flush with unassigned encoding but not empty head token, this shouldn't happen");
            }
            return RubyUtil.toRubyObject(s);
        }
    }

    @JRubyMethod(name = "empty?")
    public IRubyObject isEmpty(final ThreadContext context) {
        return RubyUtil.RUBY.newBoolean(tokenizer.isEmpty());
    }

}
