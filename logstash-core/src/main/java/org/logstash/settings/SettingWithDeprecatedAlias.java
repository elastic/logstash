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

import java.util.Arrays;
import java.util.List;


/**
 * A <code>SettingWithDeprecatedAlias</code> wraps any <code>Setting</code> to provide a deprecated
 * alias, and hooks @see org.logstash.settings.Setting#validate_value() to ensure that a deprecation
 * warning is fired when the setting is provided by its deprecated alias,
 * or to produce an error when both the canonical name and deprecated
 * alias are used together.
 * */
// This class is public else the getDeprecatedAlias method can't be seen from setting_with_deprecated_alias_spec.rb
public class SettingWithDeprecatedAlias<T> extends SettingDelegator<T> {
    
    /**
     * Wraps the provided setting, returning a pair of connected settings
     * including the canonical setting and a deprecated alias.
     * @param canonicalSetting the setting to wrap
     * @param deprecatedAliasName the name for the deprecated alias
     *
     * @return List of [SettingWithDeprecatedAlias, DeprecatedAlias]
     * */
    static <T> List<Setting<T>> wrap(BaseSetting<T> canonicalSetting, String deprecatedAliasName) {
        final SettingWithDeprecatedAlias<T> settingProxy = new SettingWithDeprecatedAlias<>(canonicalSetting, deprecatedAliasName);
        return Arrays.asList(settingProxy, settingProxy.deprecatedAlias);
    }

    private DeprecatedAlias<T> deprecatedAlias;

    @SuppressWarnings("this-escape")
    protected SettingWithDeprecatedAlias(BaseSetting<T> canonicalSetting, String deprecatedAliasName) {
        super(canonicalSetting);

        this.deprecatedAlias = new DeprecatedAlias<T>(this, deprecatedAliasName);
    }

    BaseSetting<T> getCanonicalSetting() {
        return getDelegate();
    }

    public DeprecatedAlias<T> getDeprecatedAlias() {
        return deprecatedAlias;
    }

    @Override
    public void setSafely(T value) {
        getCanonicalSetting().setSafely(value);
    }

    @Override
    public T value() {
        if (getCanonicalSetting().isSet()) {
            return super.value();
        }
        // bypass warning by querying the wrapped setting's value
        if (deprecatedAlias.isSet()) {
            return deprecatedAlias.getDelegate().value();
        }
        return getDefault();
    }

    @Override
    public boolean isSet() {
        return getCanonicalSetting().isSet() || deprecatedAlias.isSet();
    }

    @Override
    public void format(List<String> output) {
        if (!(deprecatedAlias.isSet() && !getCanonicalSetting().isSet())) {
            super.format(output);
            return;
        }
        output.add(String.format("*%s: %s (via deprecated `%s`; default: %s)",
                getName(), value(), deprecatedAlias.getName(), getDefault()));
    }

    @Override
    public void validateValue() {
        if (deprecatedAlias.isSet() && getCanonicalSetting().isSet()) {
            throw new IllegalStateException(String.format("Both `%s` and its deprecated alias `%s` have been set.\n" +
                    "Please only set `%s`", getCanonicalSetting().getName(), deprecatedAlias.getName(), getCanonicalSetting().getName()));
        }
        super.validateValue();
    }

}
