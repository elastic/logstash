### Benchmark CLI

#### Build

To build a self-contained archive of the benchmark tool simply run:

```bash
gradle clean assemble
```

which will create the output jar under `build/libs/benchmark-cli.jar`.

#### Running

```bash
$ java -cp 'benchmark-cli.jar:*' org.logstash.benchmark.cli.Main --help
Option                           Description                                    
------                           -----------                                    
--distribution-version <String>  The version of a Logstash build to download    
                                   from elastic.co.                             
--elasticsearch-export <String>  Optional Elasticsearch host URL to store       
                                   detailed results at. (default: )                       
--git-hash <String>              Either a git tree (tag/branch or commit hash), 
                                   optionally prefixed by a Github username,    
                                 if ran against forks.                          
                                 E.g.                                           
                                   'ab1cfe8cf7e20114df58bcc6c996abcb2b0650d7',  
                                 'user-                                         
                                   name#ab1cfe8cf7e20114df58bcc6c996abcb2b0650d7'
                                   or 'master'                                  
--local-path <String>            Path to the root of a local Logstash           
                                   distribution.                                
                                  E.g. `/opt/logstash`                          
--testcase <String>              Currently available test cases are 'baseline'    
                                   and 'apache'. (default: baseline)            
--workdir <File>                 Working directory to store cached files in.    
                                   (default: ~/.logstash-benchmarks)  
```

##### Example

```bash
$ java -cp 'benchmark-cli.jar:*' org.logstash.benchmark.cli.Main --workdir=/tmp/benchmark2 --testcase=baseline --distribution-version=5.5.0  
  ██╗      ██████╗  ██████╗ ███████╗████████╗ █████╗ ███████╗██╗  ██╗          
  ██║     ██╔═══██╗██╔════╝ ██╔════╝╚══██╔══╝██╔══██╗██╔════╝██║  ██║          
  ██║     ██║   ██║██║  ███╗███████╗   ██║   ███████║███████╗███████║          
  ██║     ██║   ██║██║   ██║╚════██║   ██║   ██╔══██║╚════██║██╔══██║          
  ███████╗╚██████╔╝╚██████╔╝███████║   ██║   ██║  ██║███████║██║  ██║          
  ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝          
                                                                               
  ██████╗ ███████╗███╗   ██╗ ██████╗██╗  ██╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗
  ██╔══██╗██╔════╝████╗  ██║██╔════╝██║  ██║████╗ ████║██╔══██╗██╔══██╗██║ ██╔╝
  ██████╔╝█████╗  ██╔██╗ ██║██║     ███████║██╔████╔██║███████║██████╔╝█████╔╝ 
  ██╔══██╗██╔══╝  ██║╚██╗██║██║     ██╔══██║██║╚██╔╝██║██╔══██║██╔══██╗██╔═██╗ 
  ██████╔╝███████╗██║ ╚████║╚██████╗██║  ██║██║ ╚═╝ ██║██║  ██║██║  ██║██║  ██╗
  ╚═════╝ ╚══════╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝
                                                                               
  ------------------------------------------
  Benchmarking Version: 5.5.0
  Running Test Case: baseline
  ------------------------------------------
  Start Time: Sat 7 22 21:28:45.4 2017 CEST
  Statistical Summary:
  
  Elapsed Time: 33s
  Num Events: 977816
  Throughput Min: 2000.00
  Throughput Max: 44500.00
  Throughput Mean: 37608.31
  Throughput StdDev: 8985.03
  Throughput Variance: 80730818.62
  Mean CPU Usage: 19.27%
```
