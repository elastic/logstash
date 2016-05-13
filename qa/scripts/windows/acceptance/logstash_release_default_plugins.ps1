# Created By: Gabriel Moskovicz
#
# To be run on Jenkins
#
# Requirements to run the test:
#
# - Powershell 4
# - Windows 7 or newer
# - Java 8 or newer
# - Ruby 7 or newer

$ruby = $env:RUBY_HOME  + "\jruby.exe"

sleep 30

cd rakelib

$install_default = start $ruby -ArgumentList "-S rake test:install-default" -Passthru -NoNewWindow -Wait

If ($install_default.exitCode -gt 0){
     exit 1
}

$plugins = start $ruby -ArgumentList "-S rake test:plugins" -Passthru -NoNewWindow -Wait

If ($plugins.exitCode -gt 0){
     exit 1
}