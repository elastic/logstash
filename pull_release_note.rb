require "octokit"


@repository= "logstash/logstash"
@releaseNote= "releaseNote.html"

#Last release  == last tag
lastReleaseSha = Octokit.tags(@repository).first.commit.sha

currentReleaseSha ="HEAD"

#Collect PR Merge in a file
File.open(@releaseNote, "a") do |f|
  f.puts "<h2>Merged pull request</h2>"
  f.puts "<ul>"
  Octokit.compare(@repository, lastReleaseSha, currentReleaseSha).commits.each do |commit|
    if commit.commit.message.start_with?("Merge pull")
      scan_re = Regexp.new(/^Merge pull request #(\d+) from ([^\/]+)\/.*\n\n(.*)/)
      commit.commit.message.scan(scan_re) do |pullNumber, user, summary|
        f.puts "<li><a href='https://github.com/logstash/logstash/pull/#{pullNumber}'>Pull ##{pullNumber}<a> by #{user}: #{summary}</li>"
      end
    end
  end
  f.puts "</ul>"
end