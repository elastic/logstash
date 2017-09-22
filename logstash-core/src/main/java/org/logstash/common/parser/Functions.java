package org.logstash.common.parser;

class Functions {
    public interface Function3<Arg0, Arg1, Arg2, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2);
    }

    public interface Function4<Arg0, Arg1, Arg2, Arg3, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3);
    }

    public interface Function5<Arg0, Arg1, Arg2, Arg3, Arg4, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4);
    }

    public interface Function6<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4, Arg5 arg5);
    }

    public interface Function7<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4, Arg5 arg5, Arg6 arg6);
    }

    public interface Function8<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4, Arg5 arg5, Arg6 arg6, Arg7 arg7);
    }

    public interface Function9<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4, Arg5 arg5, Arg6 arg6, Arg7 arg7, Arg8 arg8);
    }
}
