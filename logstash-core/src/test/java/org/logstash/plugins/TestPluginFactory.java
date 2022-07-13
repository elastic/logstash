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


package org.logstash.plugins;

import co.elastic.logstash.api.Codec;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.compiler.AbstractFilterDelegatorExt;
import org.logstash.config.ir.compiler.AbstractOutputDelegatorExt;
import org.logstash.config.ir.compiler.RubyIntegration;
import org.logstash.plugins.codecs.Line;

import java.util.Collections;

public class TestPluginFactory implements RubyIntegration.PluginFactory {

    @Override
    public IRubyObject buildInput(RubyString name, IRubyObject args,
                                  SourceWithMetadata source) {
        return null;
    }

    @Override
    public AbstractOutputDelegatorExt buildOutput(RubyString name, IRubyObject args,
                                                  SourceWithMetadata source) {
        return null;
    }

    @Override
    public AbstractFilterDelegatorExt buildFilter(RubyString name, IRubyObject args,
                                                  SourceWithMetadata source) {
        return null;
    }

    @Override
    public IRubyObject buildCodec(RubyString name, IRubyObject args, SourceWithMetadata source) {
        return null;
    }

    @Override
    public Codec buildDefaultCodec(String codecName) {
        return new Line(new ConfigurationImpl(Collections.emptyMap()), new ContextImpl(null, null));
    }

    @Override
    public Codec buildRubyCodecWrapper(RubyObject rubyCodec) {
        return null;
    }
}
