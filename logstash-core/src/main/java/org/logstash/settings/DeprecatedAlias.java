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

import co.elastic.logstash.api.DeprecationLogger;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.log.DefaultDeprecationLogger;

/**
 * A <code>DeprecatedAlias</code> provides a deprecated alias for a setting, and is meant
 * to be used exclusively through @see org.logstash.settings.SettingWithDeprecatedAlias#wrap()
 * */
public final class DeprecatedAlias<T> extends SettingDelegator<T> {
    private static final Logger LOGGER = LogManager.getLogger();

    private static final DeprecationLogger DEPRECATION_LOGGER = new DefaultDeprecationLogger(LOGGER);

    private SettingWithDeprecatedAlias<T> canonicalProxy;

    DeprecatedAlias(SettingWithDeprecatedAlias<T> canonicalProxy, String aliasName) {
        super(canonicalProxy.getCanonicalSetting().deprecate(aliasName));
        this.canonicalProxy = canonicalProxy;
    }

    // Because loggers are configure after the Settings declaration, this method is intended for lazy-logging
    // check https://github.com/elastic/logstash/pull/16339
    public void observePostProcess() {
        if (isSet()) {
            DEPRECATION_LOGGER.deprecated("The setting `{}` is a deprecated alias for `{}` and will be removed in a " +
                    "future release of Logstash. Please use `{}` instead", getName(), canonicalProxy.getName(), canonicalProxy.getName());
        }
    }

    @Override
    public T value() {
        LOGGER.warn("The value of setting `{}` has been queried by its deprecated alias `{}`. " +
                "Code should be updated to query `{}` instead", canonicalProxy.getName(), getName(), canonicalProxy.getName());
        return super.value();
    }

    @Override
    public void validateValue() {
        // bypass deprecation warning
        if (isSet()) {
            getDelegate().validateValue();
        }
    }
}
