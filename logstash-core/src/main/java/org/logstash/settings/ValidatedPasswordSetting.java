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

import co.elastic.logstash.api.Password;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.secret.password.PasswordPolicyParam;
import org.logstash.secret.password.PasswordPolicyType;
import org.logstash.secret.password.PasswordValidator;

import java.util.HashMap;
import java.util.Map;

public class ValidatedPasswordSetting extends PasswordSetting {

    private static final Logger LOGGER = LogManager.getLogger(ValidatedPasswordSetting.class);

    private final Map<String, Object> passwordPolicies;

    @SuppressWarnings("this-escape")
    public ValidatedPasswordSetting(String name, Object defaultValue, Map<Object, Object> passwordPolicies) {
        super(name, defaultValue, false); // this super doesn't call validate and coerce

        this.passwordPolicies = convertKeyRubyLabelsToStrings(passwordPolicies);
        Password coercedDefault = coerce(defaultValue);
        validate(coercedDefault);
        this.defaultValue = coercedDefault;
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> convertKeyRubyLabelsToStrings(Map<Object, Object> passwordPolicies) {
        Map<String, Object> result = new HashMap<>();
        for (Map.Entry<Object, Object> entry : passwordPolicies.entrySet()) {
            final String transformedKey = entry.getKey().toString();;
            Object value = entry.getValue();
            if (value instanceof Map) {
                value = convertKeyRubyLabelsToStrings((Map<Object, Object>) value);
            }
            // TODO handle lists if needed ?
            // TODO what if the value is a RubySymbol ?
            result.put(transformedKey, value);
        }
        return result;
    }

    @Override
    public Password coerce(Object password) {
        if (password != null && !(password instanceof Password)) {
            throw new IllegalArgumentException("Setting `" + getName() + "` could not coerce LogStash::Util::Password value to password");
        }
        LOGGER.info("Password policies: {}", passwordPolicies);
        Map<PasswordPolicyType, PasswordPolicyParam> policies = buildPasswordPolicies();
        String validatedResult = new PasswordValidator(policies).validate(((Password) password).getValue());

        if (!validatedResult.isEmpty()) {
            if ("WARN".equals(passwordPolicies.get("mode"))) {
                LOGGER.warn("Password {}.", validatedResult);
            } else {
                throw new IllegalArgumentException("Password "+ validatedResult + ".");
            }
        }
        return (Password) password;
    }

    private Map<PasswordPolicyType, PasswordPolicyParam> buildPasswordPolicies() {
        Map<PasswordPolicyType, PasswordPolicyParam> policies = new HashMap<>();

        policies.put(PasswordPolicyType.EMPTY_STRING, new PasswordPolicyParam());
        Object minLengthPolicyValue = dig(passwordPolicies, "length", "minimum");

        // in Ruby "nil.to_s" is "", so we do the same here
        policies.put(PasswordPolicyType.LENGTH, new PasswordPolicyParam("MINIMUM_LENGTH",
                minLengthPolicyValue != null? minLengthPolicyValue.toString() : ""));

        if ("REQUIRED".equals(dig(passwordPolicies, "include", "upper"))) {
            policies.put(PasswordPolicyType.UPPER_CASE, new PasswordPolicyParam());
        }
        if ("REQUIRED".equals(dig(passwordPolicies, "include", "lower"))) {
            policies.put(PasswordPolicyType.LOWER_CASE, new PasswordPolicyParam());
        }
        if ("REQUIRED".equals(dig(passwordPolicies, "include", "digit"))) {
            policies.put(PasswordPolicyType.DIGIT, new PasswordPolicyParam());
        }
        if ("REQUIRED".equals(dig(passwordPolicies, "include", "symbol"))) {
            policies.put(PasswordPolicyType.SYMBOL, new PasswordPolicyParam());
        }
        return policies;
    }

    private static Object dig(Map<String, Object> map, String... path) {
        Object current = map;
        for (String key : path) {
            if (!(current instanceof Map)) {
                return null;
            }
            current = ((Map<?, ?>) current).get(key);
            if (current == null) {
                return null;
            }
        }
        return current;
    }
}
