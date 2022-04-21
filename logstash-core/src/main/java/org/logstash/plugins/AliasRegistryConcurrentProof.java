package org.logstash.plugins;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.concurrent.*;

/*
 * Run with ./gradlew assemble && java -cp "logstash-core/lib/jars/*:vendor/jruby/lib/jruby.jar" org.logstash.plugins.AliasRegistryConcurrentProof
 * */
public class AliasRegistryConcurrentProof {

//    @SuppressWarnings("rawtypes")
//    public static void main(String[] args) throws ExecutionException, InterruptedException, TimeoutException {
//        int cpus = Runtime.getRuntime().availableProcessors();
//        ExecutorService pool = Executors.newFixedThreadPool(4);
//
//        List<Throwable> errors = new ArrayList<>();
//        List<Future> taskResults = new ArrayList<>(cpus * 1000);
//
//        System.out.println("Creating all tasks");
//        Runnable task = createTestTask(errors);
//        for (int i = 0; i < cpus * 1000; i++) {
//            Future<?> taskFuture = pool.submit(task);
//            taskResults.add(taskFuture);
//        }
//
//        for (Future taskResult: taskResults) {
//            taskResult.get(1_000, TimeUnit.SECONDS);
//        }
//        System.out.println("Joining all results");
//
//        pool.shutdown();
//        System.out.println("Thread pool shutdown");
//
//        printFoundErrors(errors);
//    }

    public static void main(String[] args) throws ExecutionException, InterruptedException, TimeoutException {
        int runningTime = 30_000;
        int numThreads = 10;

        ArrayBlockingQueue<Throwable> errors = new ArrayBlockingQueue<Throwable>(numThreads);
        Runnable task = new Runnable() {
            @Override
            public void run() {
                long start = System.currentTimeMillis();
                while (System.currentTimeMillis() - start <= runningTime && !Thread.currentThread().isInterrupted()) {
                    try {
                        AliasRegistry aliasRegistry = new AliasRegistry();
                        if (!"beats".equals(aliasRegistry.originalFromAlias(PluginLookup.PluginType.INPUT, "elastic_agent"))) {
                            System.out.println("Problem encountered with AliasRegistry");
                        }
                    } catch (Throwable th) {
                        errors.add(th);
                    }
                }
            }
        };

        System.out.println("Creating tasks and running them for 5 seconds");

        List<Thread> threads = new ArrayList<>(numThreads);
        for (int i = 0; i < numThreads; i++) {
            threads.add(new Thread(task));
        }

        threads.forEach(Thread::start);
        System.out.println("Started threads");

        threads.forEach(thread -> {
            try {
                thread.join();
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
        System.out.println("Joining threads and exit");

        printFoundErrors(errors);
    }

    private static void printFoundErrors(Collection<Throwable> errors) {
        if (!errors.isEmpty()) {
            System.out.printf("Terminated with %d errors%n", errors.size());
            for (Throwable error : errors) {
                System.out.println(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");
                error.printStackTrace(System.out);
                System.out.println("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<");
            }
        }
    }


    private static Runnable createTestTask(List<Throwable> errors) {
        return () -> {
            try {
                AliasRegistry aliasRegistry = new AliasRegistry();
                if (!"beats".equals(aliasRegistry.originalFromAlias(PluginLookup.PluginType.INPUT, "elastic_agent"))) {
                    System.out.println("Problem encountered with AliasRegistry");
                }
            } catch (Throwable th) {
                errors.add(th);
            }
        };
    }
}
