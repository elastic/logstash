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

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import org.jruby.RubyArray;
import org.jruby.runtime.builtin.IRubyObject;

import static org.logstash.Valuefier.convert;

public final class ConvertedList extends ArrayList<Object> {

    private static final long serialVersionUID = 1396291343595074238L;

    ConvertedList() {
        super(10);
    }

    ConvertedList(final int size) {
        super(size);
    }

    public static ConvertedList newFromList(final Collection<?> list) {
        ConvertedList array = new ConvertedList(list.size());

        for (Object item : list) {
            array.add(convert(item));
        }
        return array;
    }

    public static ConvertedList newFromRubyArray(final IRubyObject[] a) {
        final ConvertedList result = new ConvertedList(a.length);
        for (IRubyObject o : a) {
            result.add(convert(o));
        }
        return result;
    }

    public static ConvertedList newFromRubyArray(@SuppressWarnings("rawtypes") RubyArray a) {
        final ConvertedList result = new ConvertedList(a.size());

        for (IRubyObject o : a.toJavaArray()) {
            result.add(convert(o));
        }
        return result;
    }

    public List<Object> unconvert() {
        final ArrayList<Object> result = new ArrayList<>(size());
        for (Object obj : this) {
            result.add(Javafier.deep(obj));
        }
        return result;
    }

    @Override
    public String toString() {
        final StringBuffer sb = new StringBuffer("ConvertedList{");
        sb.append("delegate=").append(super.toString());
        sb.append('}');
        return sb.toString();
    }
}
