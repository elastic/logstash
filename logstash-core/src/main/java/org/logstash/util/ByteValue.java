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
package org.logstash.util;

import org.logstash.RubyUtil;

import java.math.BigDecimal;
import java.math.BigInteger;
import java.util.regex.Pattern;

/**
 * Utility class for parsing and formatting byte values.
 * Supports units: b, kb, mb, gb, tb, pb (case-insensitive).
 */
public final class ByteValue {

    public static final long B = 1L;
    public static final long KB = 1L << 10;
    public static final long MB = 1L << 20;
    public static final long GB = 1L << 30;
    public static final long TB = 1L << 40;
    public static final long PB = 1L << 50;

    private static final Pattern KB_PATTERN = Pattern.compile("(?:k|kb)$", Pattern.CASE_INSENSITIVE);
    private static final Pattern MB_PATTERN = Pattern.compile("(?:m|mb)$", Pattern.CASE_INSENSITIVE);
    private static final Pattern GB_PATTERN = Pattern.compile("(?:g|gb)$", Pattern.CASE_INSENSITIVE);
    private static final Pattern TB_PATTERN = Pattern.compile("(?:t|tb)$", Pattern.CASE_INSENSITIVE);
    private static final Pattern PB_PATTERN = Pattern.compile("(?:p|pb)$", Pattern.CASE_INSENSITIVE);
    private static final Pattern B_PATTERN = Pattern.compile("(?:b)$", Pattern.CASE_INSENSITIVE);

    private ByteValue() {
        // Utility class, not meant to be instantiated
    }

    /**
     * Parse a byte value string like "100mb" and return the value in bytes.
     * Uses double arithmetic to match Ruby's to_f behavior, then converts to BigInteger
     * to support values larger than Long.MAX_VALUE.
     *
     * @param text the string to parse (e.g., "100mb", "1gb", "500kb")
     * @return the value in bytes as BigInteger
     * @throws org.jruby.exceptions.ArgumentError if the text has an unknown unit or the numeric part of the string is not a number.
     */
    public static BigInteger parse(String text) {
        // Use Double.parseDouble to match Ruby's to_f behavior (including precision loss)
        String numericPart = text.replaceAll("[^0-9.\\-]", "");
        double number;
        try {
            number = Double.parseDouble(numericPart);
        } catch (NumberFormatException e) {
            throw RubyUtil.RUBY.newArgumentError("Unknown bytes value '" + text + "'");
        }
        long factor = multiplier(text);
        // Multiply as double (matches Ruby's Float * Integer)
        double result = number * factor;
        // Convert to BigDecimal then to BigInteger to handle values > Long.MAX_VALUE
        // Ruby's to_i truncates toward zero
        return new BigDecimal(result).toBigInteger();
    }

    /**
     * Get the multiplier for a given byte unit string.
     *
     * @param text the string containing a unit suffix (e.g., "100kb", "mb")
     * @return the multiplier for the unit
     * @throws org.jruby.exceptions.ArgumentError if the unit is unknown
     */
    public static long multiplier(String text) {
        if (KB_PATTERN.matcher(text).find()) {
            return KB;
        }
        if (MB_PATTERN.matcher(text).find()) {
            return MB;
        }
        if (GB_PATTERN.matcher(text).find()) {
            return GB;
        }
        if (TB_PATTERN.matcher(text).find()) {
            return TB;
        }
        if (PB_PATTERN.matcher(text).find()) {
            return PB;
        }
        if (B_PATTERN.matcher(text).find()) {
            return B;
        }
        throw RubyUtil.RUBY.newArgumentError("Unknown bytes value '" + text + "'");
    }

    /**
     * Convert a byte value to a human-readable string.
     *
     * @param number the value in bytes
     * @return a human-readable string (e.g., "10gb", "500mb")
     */
    public static String humanReadable(long number) {
        long value;
        String unit;

        if (number > PB) {
            value = number / PB;
            unit = "pb";
        } else if (number > TB) {
            value = number / TB;
            unit = "tb";
        } else if (number > GB) {
            value = number / GB;
            unit = "gb";
        } else if (number > MB) {
            value = number / MB;
            unit = "mb";
        } else if (number > KB) {
            value = number / KB;
            unit = "kb";
        } else {
            value = number;
            unit = "b";
        }

        return String.format("%02d%s", value, unit);
    }
}
