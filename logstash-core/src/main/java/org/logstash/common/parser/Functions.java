package org.logstash.common.parser;

class Functions {
    interface Function3<Arg0, Arg1, Arg2, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2);
    }

    interface Function4<Arg0, Arg1, Arg2, Arg3, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3);
    }

    interface Function5<Arg0, Arg1, Arg2, Arg3, Arg4, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4);
    }

    interface Function6<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4, Arg5 arg5);
    }

    interface Function7<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4, Arg5 arg5, Arg6 arg6);
    }

    interface Function8<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4, Arg5 arg5, Arg6 arg6, Arg7 arg7);
    }

    interface Function9<Arg0, Arg1, Arg2, Arg3, Arg4, Arg5, Arg6, Arg7, Arg8, Value> {
        Value apply(Arg0 arg0, Arg1 arg1, Arg2 arg2, Arg3 arg3, Arg4 arg4, Arg5 arg5, Arg6 arg6, Arg7 arg7, Arg8 arg8);
    }
}
