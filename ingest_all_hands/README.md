Add the following to `jvm.options`

```
-XX:MaxDirectMemorySize=64m
-XX:-MaxFDLimit
```

MaxDirectMemorySize : limits the direct memory used by JVM
-MaxFDLimit : on Mac avoid the JVM limiting the number of file descriptors


# Launching LS

```
ulimit -S -n 1048576 && bin/logstash -f /Users/andrea/workspace/logstash_andsel/ingest_all_hands/ssl_tcp_pipeline.conf
```

## Launching the TCP benchmark tool

```
ruby -J-Xmx16g -J-XX:-MaxFDLimit benchmark_client.rb
```

- `-MaxFDLimit` is used to avoid the FD limit imposed by the JVM

## Launching the Beats benchmark tool
Provide at least 128Mb for direct memory (MaxDirectMemorySize)

```
ruby -J-Xmx16g -J-XX:-MaxFDLimit benchmark_client.rb --test=beats -a yes -f 3
```
- `-a` is used to consumes the ACK messages
-  `-f 3` define the speed of ACKs reads per seconds.