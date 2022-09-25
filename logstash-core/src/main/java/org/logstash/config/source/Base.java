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

package org.logstash.config.source;

import org.jruby.RubyArray;
import org.jruby.RubyObject;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.config.ir.PipelineConfig;

import java.util.ArrayList;
import java.util.List;

import static org.logstash.RubyUtil.RUBY;

public class Base {
    protected RubyObject settings;
    protected List<String> conflictMessages = new ArrayList<>();

    public Base(RubyObject logstashSettings) {
        settings = logstashSettings;
    }

    public List<String> getConflictMessages() {
        return conflictMessages;
    }

    public RubyObject getSettings() {
        return settings;
    }

    // this must be used when in Ruby code was @settings = <new value>
    public void updateSettings(RubyObject settings) {
        this.settings = settings;
    }

    public List<PipelineConfig> pipelineConfigs() {
        throw new UnsupportedOperationException("`pipelineConfigs` must be implemented!");
    }

    public boolean isMatch() {
        throw new UnsupportedOperationException("`isMatch` must be implemented!");
    }

    public boolean isConfigConflict() {
        throw new UnsupportedOperationException("`isConfigConflict` must be implemented!");
    }

    //return subclass of LogStash::Setting
    public IRubyObject configReloadAutomaticSetting() {
        return this.settings.callMethod(RUBY.getCurrentContext(), "get_setting",
                RubyString.newString(RUBY, "config.reload.automatic"));
    }

    public boolean configReloadAutomatic() {
        final IRubyObject value = configReloadAutomaticSetting().callMethod(RUBY.getCurrentContext(), "value");
        return value.toJava(Boolean.class);
    }

    public boolean isConfigReloadAutomatic() {
        final IRubyObject valueIsSet = configReloadAutomaticSetting().callMethod(RUBY.getCurrentContext(), "set?");
        return valueIsSet.toJava(Boolean.class);
    }

    //return subclass of LogStash::Setting
    public IRubyObject configStringSetting() {
        return this.settings.callMethod(RUBY.getCurrentContext(), "get_setting",
                RubyString.newString(RUBY, "config.string"));
    }

    public String configString() {
        final IRubyObject setting = configStringSetting();
        final IRubyObject value = setting.callMethod(RUBY.getCurrentContext(), "value");
        return value.toJava(String.class);
    }

    public boolean isConfigString() {
        return configString() != null;
    }

    // return subclass of LogStash::Setting
    public IRubyObject configPathSetting() {
        return this.settings.callMethod(RUBY.getCurrentContext(), "get_setting",
                RubyString.newString(RUBY, "path.config"));
    }

    public String configPath() {
        return configPathSetting().callMethod(RUBY.getCurrentContext(), "value").toJava(String.class);
    }

    public boolean isConfigPath() {
        return !(configPath() == null || configPath().isEmpty());
    }

    // return subclass of LogStash::Setting
    public IRubyObject modulesCliSetting() {
        return this.settings.callMethod(RUBY.getCurrentContext(), "get_setting",
                RubyString.newString(RUBY, "modules.cli"));
    }

    @SuppressWarnings("rawtypes")
    public RubyArray modulesCli() {
        return modulesCliSetting().callMethod(RUBY.getCurrentContext(), "value").convertToArray();
    }

    public boolean isModulesCli() {
        return !(modulesCli() == null || modulesCli().isEmpty());
    }

    // return subclass of LogStash::Setting
    public IRubyObject modulesSetting() {
        return this.settings.callMethod(RUBY.getCurrentContext(), "get_setting",
                RubyString.newString(RUBY, "modules"));
    }

    @SuppressWarnings("rawtypes")
    public RubyArray modules() {
        return (RubyArray) modulesSetting().callMethod(RUBY.getCurrentContext(), "value");
    }

    public boolean isModules() {
        return !(modules() == null || modules().isEmpty());
    }

    public boolean isBothModuleConfigs() {
        return isModulesCli() && isModules();
    }

    public boolean isModulesDefined() {
        return isModulesCli() || isModules();
    }
}
