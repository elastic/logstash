package com.logstash;

import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;

import java.util.*;

public class RubyToJavaConverter {

    public static Object convert(IRubyObject obj) {
        if (obj instanceof RubyArray) {
            return convertToList((RubyArray) obj);
        } else if (obj instanceof RubyHash) {
            return convertToMap((RubyHash) obj);
        } else if (obj instanceof RubyString) {
            return convertToString((RubyString) obj);
        }

        return obj.toJava(obj.getJavaClass());
    }

    public static HashMap<String, Object> convertToMap(RubyHash hash) {
        HashMap<String, Object> hashMap = new HashMap();
        Set<RubyHash.RubyHashEntry> entries = hash.directEntrySet();
        for (RubyHash.RubyHashEntry e : entries) {
            hashMap.put(e.getJavaifiedKey().toString(), convert((IRubyObject) e.getValue()));
        }
        return hashMap;
    }

    public static List<Object> convertToList(RubyArray array) {
        ArrayList<Object> list = new ArrayList();
        for (IRubyObject obj : array.toJavaArray()) {
            list.add(convert(obj));
        }

        return list;
    }

    public static String convertToString(RubyString string) {
        return string.decodeString();
    }
}
