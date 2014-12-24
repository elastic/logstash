

task "bootstrap" => [ "vendor:all", "compile:all" ]

task "bootstrap:test" => [ "vendor:test", "compile:all" ]
