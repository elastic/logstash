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


package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Codec;
import org.apache.commons.codec.digest.DigestUtils;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.common.SourceWithMetadata;

import java.util.Random;

/**
 * This class holds interfaces implemented by Ruby concrete classes.
 */
public final class RubyIntegration {

    private RubyIntegration() {
        //Utility Class.
    }

    /**
     * Plugin Factory that instantiates Ruby plugins and is implemented in Ruby.
     */
    public interface PluginFactory {

        IRubyObject buildInput(RubyString name, IRubyObject args, SourceWithMetadata source);

        AbstractOutputDelegatorExt buildOutput(RubyString name, IRubyObject args, SourceWithMetadata source);

        AbstractFilterDelegatorExt buildFilter(RubyString name, IRubyObject args, SourceWithMetadata source);

        IRubyObject buildCodec(RubyString name, IRubyObject args, SourceWithMetadata source);

        Codec buildDefaultCodec(String codecName);

    }

    /**
     * Generates a plugin id.
     * @return a (random) generated plugin identifier
     */
    public static String generatePluginId() {
        // similar to UUID.randomUUID() but fast - we do not need "secure" random ids
        byte[] randomBytes = new byte[16];
        new Random().nextBytes(randomBytes); // seeded from System.nanoTime()
        // for improved log readability we limit the HEX string to a shorter length
        return new DigestUtils("MD5").digestAsHex(randomBytes).substring(0, 16);
    }

}
