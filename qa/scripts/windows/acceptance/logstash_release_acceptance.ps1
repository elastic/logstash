# Created By: Gabriel Moskovicz
#
# To be run on Jenkins
#
# Requirements to run the test:
#
# - Powershell 4
# - Windows 7 or newer
# - Java 8 or newer

$LS_CONFIG="test.conf"
$LS_BRANCH=$env:LS_BRANCH
$Logstash_path = "C:\logstash"
$Logstash_Snapshot_Directory = "$Logstash_path\logstash-latest-SNAPSHOT.zip"
$Logstash_URL = "https://s3-eu-west-1.amazonaws.com/build-eu.elasticsearch.org/logstash/$LS_BRANCH/nightly/JDK7/logstash-latest-SNAPSHOT.zip"

If (Test-Path $Logstash_path){
	ri -Recurse -Force $Logstash_path
}

md -Path $Logstash_path
(New-Object System.Net.WebClient).DownloadFile($Logstash_URL, $Logstash_Snapshot_Directory)

#Unzip file
$Destination = "$Logstash_path\logstash_" + $LS_BRANCH
Add-Type -assembly "system.io.compression.filesystem"
[io.compression.zipfile]::ExtractToDirectory($Logstash_Snapshot_Directory, $Destination)

#Remove old files
ri $Logstash_Snapshot_Directory

#Move folder
cd $Destination
mv log* logstash
cd logstash

#Create Configuration
ni $LS_CONFIG -it file
sc -Path $LS_CONFIG -Encoding ascii -Value "input {
	tcp {
			port => "+ (Get-Random -minimum 2000 -maximum 3000) +"
		}
	}

output {
	stdout { }
}"

#Start Process
$app = start .\bin\logstash.bat -ArgumentList "-f $LS_CONFIG" -PassThru -NoNewWindow
sleep 30

$RUNNING_TEST = $app.Id

$PORT_TEST = netstat -na | select-string 2000

If ($RUNNING_TEST -le 0){
  echo "Logstash not running"
  exit 1
}

echo "Logstash running"

echo "Port: $PORT_TEST"

If ($PORT_TEST.length -le  0){
  echo "Port test failed"
  exit 1
}

taskkill /PID $app.Id /F /T