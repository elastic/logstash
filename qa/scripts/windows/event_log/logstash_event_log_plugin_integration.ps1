# Created By: Gabriel Moskovicz
#
# This is a script to test integration between logstash and elasticsearch.
# It uses a simple json filter to parse the content of a simple text file an then
# verifying if the message has been found in elasticsearch
#
# Requirements to run the test:
#
# - Powershell 4
# - Windows 7 or newer
# - Java 8 or newer

Add-Type -assembly "system.io.compression.filesystem"


$Main_path = "C:\integration_test"
If (Test-Path $Main_path){
	ri -Recurse -Force $Main_path
}
$Download_path  = "$Main_path\download"
md -Path $Download_path

## Logstash variables

$LS_CONFIG="test.conf"
$LS_BRANCH=$env:LS_BRANCH
$Logstash_path = "$Main_path\logstash"
$Logstash_zip_file = "$Download_path\logstash.zip"
$Logstash_URL = "https://s3-eu-west-1.amazonaws.com/build-eu.elasticsearch.org/logstash/$LS_BRANCH/nightly/JDK7/logstash-latest-SNAPSHOT.zip"

## ----------------------------------------

## Elasticsearch variables

$ES_Version = $env:ES_VERSION
$ES_path = "$Main_path\elasticsearch"
$ES_zip_file = "$Main_path\download\elasticsearch.zip"
$ES_URL = "https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-$ES_Version.zip"

## ----------------------------------------

## Download and unzip Logstash

md -Path $Logstash_path
(New-Object System.Net.WebClient).DownloadFile($Logstash_URL, $Logstash_zip_file)
[System.IO.Compression.ZipFile]::ExtractToDirectory($Logstash_zip_file, $Download_path)
ri $Logstash_zip_file
mv "$Download_path\log*\*" $Logstash_path

## --------------------------------


## Download and unzip Elasticsearch

md -Path $ES_path
(New-Object System.Net.WebClient).DownloadFile($ES_URL, $ES_zip_file)
[System.IO.Compression.ZipFile]::ExtractToDirectory($ES_zip_file, $Download_path)
ri $ES_zip_file
mv "$Download_path\elastic*\*" "$ES_path"

## --------------------------------


# START ELASTICSEARCH

echo "Starting Elasticsearch"
$elasticsearchApp = start "$ES_path\bin\elasticsearch" -PassThru
echo "Elasticsearch running"
sleep 30

# -------------------------------------------


# Create logstash Configuration

ni "$Logstash_path\$LS_CONFIG" -it file
sc -Path "$Logstash_path\$LS_CONFIG" -Encoding ascii -Value "input {
    eventlog {
        logfile  => 'Application'
    }
}

filter {
    mutate {
        replace => { 'type' => '%{SourceName}' }
        remove_field => [ 'Type', 'Message' ]
    }
}

output {
	elasticsearch {
        protocol => http
        index => 'windows_eventlog_test_index'
    }
    stdout { codec => rubydebug }
}"

# -------------------------------------------


# START LOGSTASH

echo "Starting Logstash"
$logstashApp = start "$Logstash_path\bin\logstash" -ArgumentList "-f $Logstash_path\$LS_CONFIG" -PassThru
echo "Logstash running"
sleep 30

# -------------------------------------------

New-EventLog -LogName Application -Source ElasticsearchSource
Write-EventLog -LogName Application -Source ElasticsearchSource -EntryType Information -EventId 1 -Message "Example log Entry"

sleep 15

$searchresponse = curl "http://localhost:9200/windows_eventlog_test_index/ElasticsearchSource/_search" -UseBasicParsing
$json_response = ConvertFrom-Json $searchresponse.Content
$hit_source = $json_response.hits.hits[0]._source

If (!($hit_source.SourceName -eq "ElasticsearchSource")){
    echo "ERROR: Message was not indexed. Wrong Source Name. Test unsuccessful. Expected 'ElasticsearchSource' Received " + $hit_source.SourceName
    exit 1
}

If (!($hit_source.EventCode -eq 1)){
    echo "ERROR: Wrong expected value: EventCode. Test unsuccessful. Expected 1 Received " + $hit_source.EventCode
    exit 1
}

If (!($hit_source.message -eq "Example log Entry")){
    echo "ERROR: Wrong expected value: Message. Text Test unsuccessful. Expected 'Example log Entry' Received " + $hit_source.message
    exit 1
}

echo "Test Succeeded"

taskkill /PID $logstashApp.Id
taskkill /PID $elasticsearchApp.Id /T