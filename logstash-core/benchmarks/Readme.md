# Logstash Microbenchmark Suite

This directory contains the microbenchmark suite of Logstash. It relies on [JMH](http://openjdk.java.net/projects/code-tools/jmh/).

## Getting Started

Just run `./gradlew jmh` from the project root directory. It will build all microbenchmarks, execute them and print the result.

#### Example Output

```bash
➜  logstash: ./gradlew jmh
# JMH 1.18 (released 66 days ago)
# VM version: JDK 1.8.0_121, VM 25.121-b13
# VM invoker: /Library/Java/JavaVirtualMachines/jdk1.8.0_121.jdk/Contents/Home/jre/bin/java
# VM options: -Dfile.encoding=US-ASCII -Duser.country=US -Duser.language=en -Duser.variant
# Warmup: 3 iterations, 100 ms each
# Measurement: 10 iterations, 100 ms each
# Timeout: 10 min per iteration
# Threads: 1 thread, will synchronize iterations
# Benchmark mode: Throughput, ops/time
# Benchmark: org.logstash.benchmark.QueueBenchmark.pushToPersistedQueue

# Run progress: 0.00% complete, ETA 00:00:01
# Fork: 1 of 1
# Warmup Iteration   1: 249.325 ops/ms
# Warmup Iteration   2: 290.150 ops/ms
# Warmup Iteration   3: 293.669 ops/ms
Iteration   1: 315.075 ops/ms
Iteration   2: 282.020 ops/ms
Iteration   3: 317.281 ops/ms
Iteration   4: 296.559 ops/ms
Iteration   5: 302.803 ops/ms
Iteration   6: 305.187 ops/ms
Iteration   7: 320.959 ops/ms
Iteration   8: 304.073 ops/ms
Iteration   9: 297.499 ops/ms
Iteration  10: 301.889 ops/ms


Result "org.logstash.benchmark.QueueBenchmark.pushToPersistedQueue":
  304.334 ?(99.9%) 17.264 ops/ms [Average]
  (min, avg, max) = (282.020, 304.334, 320.959), stdev = 11.419
  CI (99.9%): [287.070, 321.599] (assumes normal distribution)


# Run complete. Total time: 00:00:22

Benchmark                             Mode  Cnt    Score    Error   Units
QueueBenchmark.pushToPersistedQueue  thrpt   10  304.334 ? 17.264  ops/ms

```

## More

Additional information on JMH can be found in the Elasticsearch project's [benchmark documentation](https://github.com/elastic/elasticsearch/blob/master/benchmarks/README.md).
