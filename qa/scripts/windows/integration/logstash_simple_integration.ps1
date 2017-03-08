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

$ES_Version =$env:ES_VERSION
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


# Create logstash Configuration and Files

ni "$Logstash_path\logs.txt" -it file
sc -Path "$Logstash_path\logs.txt" -Encoding ascii -Value "{ ""ismessage"": true, ""day"": 2, ""text"": ""test message"" }"

ni "$Logstash_path\$LS_CONFIG" -it file
$logstash_config = "input {
	file {
			path => ['$Logstash_path\logs.txt']
            start_position => 'beginning'
		}
}

filter {
    json {
        source => 'message'
    }
}

output {
	elasticsearch { "

if ( [convert]::ToDouble($LS_BRANCH) -lt 2 ) {
    $logstash_config = $logstash_config + "
        protocol => http"
}

$logstash_config = $logstash_config + "
        index => 'windows_test_index'
    }
    stdout { codec => rubydebug }
}"


sc -Path "$Logstash_path\$LS_CONFIG" -Encoding ascii -Value $logstash_config

# -------------------------------------------


# START LOGSTASH

echo "Starting Logstash"
$logstashApp = start "$Logstash_path\bin\logstash" -ArgumentList "-f $Logstash_path\$LS_CONFIG" -PassThru
echo "Logstash running"
sleep 30

# -------------------------------------------


$searchresponse = curl "http://localhost:9200/windows_test_index/_search" -UseBasicParsing
$json_response = ConvertFrom-Json $searchresponse.Content
$hit_source = $json_response.hits.hits[0]._source

If (!$hit_source.ismessage){
    echo "ERROR: Message was not indexed. Test unsuccessful. Expected true, got false".
    exit 1
}

If (!($hit_source.day -eq 2)){
    echo "ERROR: Wrong expected value. Test unsuccessful. Expected 2, got " + $hit_source.day
    exit 1
}

If (!($hit_source.text -eq "test message")){
    echo "ERROR: Wrong expected value. Test unsuccessful. Expected 'test message', got " + $hit_source.text
    exit 1
}

echo "Test Succeeded"

taskkill /PID $logstashApp.Id
taskkill /PID $elasticsearchApp.Id /T