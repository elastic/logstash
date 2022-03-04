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


package org.logstash.secret;

import java.util.Locale;
import java.util.regex.Pattern;

/**
 * <p>A URN based identifier for a given secret. The URN is constructed as such: {@code urn:logstash:secret:v1:<key>}</p>
 * <p><em>Note - v1 is the version of the URN (not the key). This allows for passive changes to the URN for anything to the right of v1</em></p>
 */
public class SecretIdentifier {

    private final static Pattern colonPattern = Pattern.compile(":");
    private final static String VERSION = "v1";
    private final static Pattern urnPattern = Pattern.compile("urn:logstash:secret:"+ VERSION + ":.*$");
    private final String key;

    /**
     * Constructor
     *
     * @param key The unique part of the identifier. This is the key to reference the secret, and the key itself should not be sensitive. For example: {@code db.pass}
     */
    public SecretIdentifier(String key) {
        this.key = validateWithTransform(key, "key");
    }

    /**
     * Converts an external URN format to a {@link SecretIdentifier} object.
     *
     * @param urn The {@link String} formatted identifier obtained originally from {@link SecretIdentifier#toExternalForm()}
     * @return The {@link SecretIdentifier} object used to identify secrets, null if not valid external form.
     */
    public static SecretIdentifier fromExternalForm(String urn) {
        if (urn == null || !urnPattern.matcher(urn).matches()) {
            throw new IllegalArgumentException("Invalid external form " + urn);
        }
        String[] parts = colonPattern.split(urn, 5);
        return new SecretIdentifier(validateWithTransform(parts[4], "key"));
    }

    /**
     * Minor validation and downcases the parts
     *
     * @param part     The part of the URN to validate
     * @param partName The name of the part used for logging.
     * @return The validated and transformed part.
     */
    private static String validateWithTransform(String part, String partName) {
        if (part == null || part.isEmpty()) {
            throw new IllegalArgumentException(String.format("%s may not be null or empty", partName));
        }
        return part.toLowerCase(Locale.US);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;

        SecretIdentifier that = (SecretIdentifier) o;

        if (key != null ? !key.equals(that.key) : that.key != null) return false;
        return true;
    }

    /**
     * Get the key (unique part) of the identifier
     *
     * @return the unique part of the identifier
     */
    public String getKey() {
        return key;
    }

    @Override
    public int hashCode() {
        int result = key != null ? key.hashCode() : 0;
        result = 31 * result + (VERSION != null ? VERSION.hashCode() : 0);
        return result;
    }

    /**
     * Converts this object to a format acceptable external {@link String} format. Note - no guarantees are made with respect to encoding or safe use. For example, the external
     * format may not be URL safely encoded.
     *
     * @return the externally formatted {@link String}
     */
    public String toExternalForm() {
        StringBuilder sb = new StringBuilder(100);
        sb.append("urn").append(":");
        sb.append("logstash").append(":");
        sb.append("secret").append(":");
        sb.append(VERSION).append(":");
        sb.append(this.key);
        return sb.toString();
    }

    @Override
    public String toString() {
        return toExternalForm();
    }
}
