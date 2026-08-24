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
package org.logstash.health;

import com.google.common.io.Resources;
import org.logstash.Logstash;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.nio.charset.StandardCharsets;
import java.util.Objects;

public class HelpUrl {
    static final String BASE_URL;
    static {
        try {
            final URL url = HelpUrl.class.getResource("/help.url");
            if (url == null) {
                throw new IllegalStateException("Unable to locate 'help.url' resource");
            }
            BASE_URL = Resources.toString(url, StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new IllegalStateException("Failed to load help.url resource", e);
        }
    }

    public HelpUrl(final String page) {
        this(page, null);
    }

    public HelpUrl withAnchor(final String anchor) {
        return new HelpUrl(this.page, anchor);
    }

    private HelpUrl(final String page, final String anchor) {
        Objects.requireNonNull(page, "page cannot be null");
        this.page = page;
        this.anchor = anchor;
    }

    private final String page;
    private final String anchor;

    private transient String resolved;

    @Override
    public String toString() {
        if (resolved == null) {
            final StringBuilder sb = new StringBuilder(BASE_URL);
            sb.append(page).append(".html");
            if (anchor != null) {
                sb.append("#").append(anchor);
            }
            resolved = sb.toString();
        }
        return resolved;
    }
}
