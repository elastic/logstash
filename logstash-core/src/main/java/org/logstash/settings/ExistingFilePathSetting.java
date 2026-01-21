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
package org.logstash.settings;

import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.function.Predicate;

public class ExistingFilePathSetting extends BaseSetting<String> {

    public ExistingFilePathSetting(String name, String defaultValue, boolean strict) {
        super(name, defaultValue, strict, new Predicate<String>() {
            @Override
            public boolean test(String filePath) {
                // when path is null, we skip existence check
                if (filePath == null) {
                    return true;
                }

                if (!Files.exists(Paths.get(filePath))) {
                    throw new IllegalArgumentException(
                            String.format("File \"%s\" must exist but was not found.", filePath));
                }

                return true;
            }
        });
    }
}
