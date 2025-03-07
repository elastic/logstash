---
mapped_pages:
  - https://www.elastic.co/guide/en/logstash/current/running-logstash-windows.html
---

# Running Logstash on Windows [running-logstash-windows]

Before reading this section, see [Installing Logstash](/reference/installing-logstash.md) to get started.  You also need to be familiar with [Running Logstash from the Command Line](/reference/running-logstash-command-line.md) as command line options are used to test running Logstash on Windows.

::::{important}
Specifying command line options is useful when you are testing Logstash. However, in a production environment, we recommend that you use [logstash.yml](/reference/logstash-settings-file.md) to control Logstash execution. Using the settings file makes it easier for you to specify multiple options, and it provides you with a single, versionable file that you can use to start up Logstash consistently for each run.
::::


Logstash is not started automatically after installation. How to start and stop Logstash on Windows depends on whether you want to run it manually, as a service (with [NSSM](https://nssm.cc/)), or run it as a scheduled task. This guide provides an example of some of the ways Logstash can run on Windows.

::::{note}
It is recommended to validate your configuration works by running Logstash manually before running Logstash as a service or a scheduled task.
::::


## Validating JVM prerequisites on Windows [running-logstash-windows-validation]

After installing a [supported JVM](https://www.elastic.co/support/matrix#matrix_jvm), open a [PowerShell](https://docs.microsoft.com/en-us/powershell/) session and run the following commands to verify `LS_JAVA_HOME` is set and the Java version:

### `Write-Host $env:LS_JAVA_HOME` [_write_host_envls_java_home]

* The output should be pointed to where the JVM software is located, for example:

    ```sh
    PS C:\> Write-Host $env:LS_JAVA_HOME
    C:\Program Files\Java\jdk-11.0.3
    ```

* If `LS_JAVA_HOME` is not set, perform one of the following:

    * Set using the GUI:

        * Navigate to the Windows [Environmental Variables](https://docs.microsoft.com/en-us/windows/win32/procthread/environment-variables) window
        * In the Environmental Variables window, edit LS_JAVA_HOME to point to where the JDK software is located, for example: `C:\Program Files\Java\jdk-11.0.3`

    * Set using PowerShell:

        * In an Administrative PowerShell session, execute the following [SETX](https://docs.microsoft.com/en-us/windows-server/administration/windows-commands/setx) commands:

            ```sh
            PS C:\Windows\system32> SETX /m LS_JAVA_HOME "C:\Program Files\Java\jdk-11.0.3"
            PS C:\Windows\system32> SETX /m PATH "$env:PATH;C:\Program Files\Java\jdk-11.0.3\bin;"
            ```

        * Exit PowerShell, then open a new PowerShell session and run `Write-Host $env:LS_JAVA_HOME` to verify



### `Java -version` [_java_version]

* This command produces output similar to the following:

    ```sh
    PS C:\> Java -version
    java version "11.0.3" 2019-04-16 LTS
    Java(TM) SE Runtime Environment 18.9 (build 11.0.3+12-LTS)
    Java HotSpot(TM) 64-Bit Server VM 18.9 (build 11.0.3+12-LTS, mixed mode)
    ```


Once you have [*Setting Up and Running Logstash*](/reference/setting-up-running-logstash.md) and validated JVM pre-requisites, you may proceed.

::::{note}
For the examples listed below, we are running Windows Server 2016, Java 11.0.3, have extracted the [Logstash ZIP package](https://www.elastic.co/downloads/logstash) to `C:\logstash-9.0.0\`, and using the example `syslog.conf` file shown below (stored in `C:\logstash-9.0.0\config\`).
::::




## Running Logstash manually [running-logstash-windows-manual]

Logstash can be run manually using [PowerShell](https://docs.microsoft.com/en-us/powershell/).  Open an Administrative [PowerShell](https://docs.microsoft.com/en-us/powershell/) session, then run the following commands:

```sh
PS C:\Windows\system32> cd C:\logstash-9.0.0\
PS C:\logstash-9.0.0> .\bin\logstash.bat -f .\config\syslog.conf
```

::::{note}
In a production environment, we recommend that you use [logstash.yml](/reference/logstash-settings-file.md) to control Logstash execution.
::::


Wait for the following messages to appear, to confirm Logstash has started successfully:

```sh
[logstash.runner          ] Starting Logstash {"logstash.version"=>"9.0.0"}
[logstash.inputs.udp      ] Starting UDP listener {:address=>"0.0.0.0:514"}
[logstash.agent           ] Successfully started Logstash API endpoint {:port=>9600}
```


## Running Logstash as a service with NSSM [running-logstash-windows-nssm]

::::{note}
It is recommended to validate your configuration works by running Logstash manually before you proceed.
::::


Download [NSSM](https://nssm.cc/), then extract `nssm.exe` from `nssm-<version.number>\win64\nssm.exe` to `C:\logstash-9.0.0\bin\`. Then open an Administrative [PowerShell](https://docs.microsoft.com/en-us/powershell/) session, then run the following commands:

```sh
PS C:\Windows\system32> cd C:\logstash-9.0.0\
PS C:\logstash-9.0.0> .\bin\nssm.exe install logstash
```

Once the `NSSM service installer` window appears, specify the following parameters in the `Application` tab:

* In the `Application` tab:

    * Path: Path to `logstash.bat`: `C:\logstash-9.0.0\bin\logstash.bat`
    * Startup Directory: Path to the `bin` directory: `C:\logstash-9.0.0\bin`
    * Arguments: For this example to start Logstash: `-f C:\logstash-9.0.0\config\syslog.conf`

        ::::{note}
        In a production environment, we recommend that you use [logstash.yml](/reference/logstash-settings-file.md) to control Logstash execution.
        ::::

* Review and make any changes necessary in the `Details` tab:

    * Ensure `Startup Type` is set appropriately
    * Set the `Display name` and `Description` fields to something relevant

* Review any other required settings (for the example we aren’t making any other changes)

    * Be sure to determine if you need to set the `Log on` user

* Validate the `Service name` is set appropriately

    * For this example, we will set ours to `logstash-syslog`

* Click `Install Service`

    * Click *OK* when the `Service "logstash-syslog" installed successfully!` window appears


Once the service has been installed with NSSM, validate and start the service following the [PowerShell Managing Services](https://docs.microsoft.com/en-us/powershell/scripting/samples/managing-services) documentation.


## Running Logstash with Task Scheduler [running-logstash-windows-scheduledtask]

::::{note}
It is recommended to validate your configuration works by running Logstash manually before you proceed.
::::


Open the Windows [Task Scheduler](https://docs.microsoft.com/en-us/windows/desktop/taskschd/task-scheduler-start-page), then click `Create Task` in the Actions window.  Specify the following parameters in the `Actions` tab:

* In the `Actions` tab:

    * Click `New`, then specify the following:
    * Action: `Start a program`
    * Program/script: `C:\logstash-9.0.0\bin\logstash.bat`
    * Add arguments: `-f C:\logstash-9.0.0\config\syslog.conf`
    * Start in: `C:\logstash-9.0.0\bin\`

        ::::{note}
        In a production environment, we recommend that you use [logstash.yml](/reference/logstash-settings-file.md) to control Logstash execution.
        ::::

* Review and make any changes necessary in the `General`, `Triggers`, `Conditions`, and `Settings` tabs.
* Click `OK` to finish creating the scheduled task.
* Once the new task has been created, either wait for it to run on the schedule or select the service then click `Run` to start the task.

::::{note}
Logstash can be stopped by selecting the service, then clicking `End` in the Task Scheduler window.
::::



## Example Logstash Configuration [running-logstash-windows-example]

We will configure Logstash to listen for syslog messages over port 514 with this configuration (file name is `syslog.conf`):

```yaml
# Sample Logstash configuration for receiving
# UDP syslog messages over port 514

input {
  udp {
    port => 514
    type => "syslog"
  }
}

output {
  elasticsearch { hosts => ["localhost:9200"] }
  stdout { codec => rubydebug }
}
```


