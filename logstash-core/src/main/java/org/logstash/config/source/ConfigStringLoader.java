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

package org.logstash.config.source;

import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.Defaults;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Pattern;

public class ConfigStringLoader {

    private static Pattern INPUT_BLOCK_RE = Pattern.compile("input\\s*\\{");
    private static Pattern OUTPUT_BLOCK_RE = Pattern.compile("output\\s*\\{");
    private static Pattern EMPTY_RE = Pattern.compile("^\\s*$");

    public static List<SourceWithMetadata> read(String configString) throws IncompleteSourceWithMetadataException {
        List<SourceWithMetadata> configParts = new ArrayList<>();
        configParts.add(new SourceWithMetadata("string", "config_string", 0, 0, configString));

//        Make sure we have an input and at least 1 output
//        if its not the case we will add stdin and stdout
//        this is for backward compatibility reason
        if (!INPUT_BLOCK_RE.matcher(configString).find()) {
            configParts.add(new SourceWithMetadata(ConfigStringLoader.class.getName(), "default input", 0, 0, Defaults.input()));
        }
//        include a default stdout output if no outputs given
        if (!OUTPUT_BLOCK_RE.matcher(configString).find()) {
            configParts.add(new SourceWithMetadata(ConfigStringLoader.class.getName(), "default output", 0, 0, Defaults.output()));
        }
        return configParts;
    }
}
