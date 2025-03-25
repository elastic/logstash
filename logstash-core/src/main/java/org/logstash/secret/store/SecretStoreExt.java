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


package org.logstash.secret.store;

import org.jruby.RubyHash;
import org.logstash.RubyUtil;
import org.logstash.secret.SecretIdentifier;

/**
 * Collect static methods to access Java keystore
 * */
public class SecretStoreExt {

    private static final SecretStoreFactory SECRET_STORE_FACTORY = SecretStoreFactory.fromEnvironment();

    public static SecureConfig getConfig(final String keystoreFile, final String keystoreClassname) {
        return getSecureConfig(RubyUtil.RUBY.getENV(), keystoreFile, keystoreClassname);
    }

    private static SecureConfig getSecureConfig(final RubyHash env, final String file, final String classname) {
        String keystorePass = (String) env.get("LOGSTASH_KEYSTORE_PASS");
        return getSecureConfig(file, keystorePass, classname);
    }

    private static SecureConfig getSecureConfig(final String keystoreFile, final String keystorePass, final String keystoreClassname) {
        if (keystoreFile == null || keystoreClassname == null) {
            throw new IllegalArgumentException("`keystore.file` and `keystore.classname` cannot be null");
        }

        SecureConfig sc = new SecureConfig();
        sc.add("keystore.file", keystoreFile.toCharArray());
        if (keystorePass != null) {
            sc.add("keystore.pass", keystorePass.toCharArray());
        }
        sc.add("keystore.classname", keystoreClassname.toCharArray());
        return sc;
    }

    public static boolean exists(final String keystoreFile, final String keystoreClassname) {
        return SECRET_STORE_FACTORY.exists(getConfig(keystoreFile, keystoreClassname));
    }

    public static SecretStore getIfExists(final String keystoreFile, final String keystoreClassname) {
        SecureConfig sc = getConfig(keystoreFile, keystoreClassname);
        return SECRET_STORE_FACTORY.exists(sc)
                ? SECRET_STORE_FACTORY.load(sc)
                : null;
    }

    public static SecretIdentifier getStoreId(final String id) {
        return new SecretIdentifier(id);
    }
}
