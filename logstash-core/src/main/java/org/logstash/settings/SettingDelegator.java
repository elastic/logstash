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

import java.util.List;
import java.util.Objects;
import java.util.function.Predicate;

abstract class SettingDelegator<T> extends Setting<T> {
    private Setting<T> delegate;

    protected SettingDelegator(String name, T defaultValue, boolean strict, Predicate<T> validator) {
        super(name, defaultValue, strict, validator);
        throw new RuntimeException("This constructor shouldn't be invoked");
    }

    /**
     * Use this constructor to wrap another setting.
     * */
    SettingDelegator(Setting<T> delegate) {
        super(delegate.getName(), delegate.getDefault(), delegate.isStrict(), noValidator());
        Objects.requireNonNull(delegate);
        this.delegate = delegate;
    }

    Setting<T> getDelegate() {
        return delegate;
    }

    @Override
    public String getName() {
        return delegate.getName();
    }

    @Override
    public T value() {
        return delegate.value();
    }

    @Override
    public boolean isSet() {
        return delegate.isSet();
    }

    @Override
    public boolean isStrict() {
        return delegate.isStrict();
    }

    @Override
    public void set(T newValue) {
        delegate.set(newValue);
    }

    @Override
    public void reset() {
        delegate.reset();
    }

    @Override
    public void validateValue() {
        delegate.validateValue();
    }

    @Override
    public T getDefault() {
        return delegate.getDefault();
    }

    @Override
    public void format(List<String> output) {
        delegate.format(output);
    }
}
