
# offline with seccomp

This is a little hack I wrote while trying to see if seccomp could be used to
help me more easily test programs in "offline mode" without having to actually
disable networking on my whole laptop.

Building:

```
make offline
```

Usage:

```
./offline <program> [args]
```

Example:

```
% nc localhost 10000
Ncat: Connection refused.

% ./offline nc localhost 10000
Ncat: Permission denied.

% ./offline host google.com
host: isc_socket_bind: permission denied
```
