package org.logstash.plugins.internal;

import org.logstash.ext.JrubyEventExtLibrary;

import java.util.Collection;
import java.util.function.Function;

public interface InternalOutput {
    void updateAddressReceiver(String address, Function<JrubyEventExtLibrary.RubyEvent, Boolean> rubyEvent);

    void removeAddressReceiver(String address);
}
