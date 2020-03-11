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


package org.logstash;

/**
 * Exception thrown by {@link Javafier}, {@link Rubyfier} and {@link Valuefier} if trying to convert
 * an illegal argument type.
 */
final class MissingConverterException extends RuntimeException {

    private static final long serialVersionUID = 1L;

    MissingConverterException(final Class<?> cls) {
        super(
            String.format(
                "Missing Converter handling for full class name=%s, simple name=%s",
                cls.getName(), cls.getSimpleName()
            )
        );
    }
}
