/*
 * Licensed to Elasticsearch under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */
package org.logstash.log;

import org.apache.logging.log4j.core.selector.ContextSelector;
import org.apache.logging.log4j.junit.LoggerContextRule;
import org.junit.rules.TestRule;
import org.junit.runner.Description;
import org.junit.runners.model.Statement;

public class LogEventFactoryRule extends LoggerContextRule {

    public LogEventFactoryRule(String configLocation, Class<? extends ContextSelector> contextSelectorClass) {
        super(configLocation, contextSelectorClass);
    }

    public Statement apply(final Statement base, final Description description) {
        Statement parent = super.apply(base, description);
       return new Statement() {
           public void evaluate() throws Throwable {
               System.setProperty("Log4jLogEventFactory", "org.logstash.log.CustomLogEventFactory");
               try {
                   parent.evaluate();
               } finally {
                   System.clearProperty("Log4jLogEventFactory");
               }
           }
       };
    }
}
