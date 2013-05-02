require "octokit"
##
# This script will validate that any pull request submitted against a github 
# repository will contains changes to CHANGELOG file.
#
# If not the case, an helpful text will be commented on the pull request
# If ok, a thanksful message will be commented also containing a @mention to 
# acts as a trigger for review notification by a human.
## 


@bot="" # Put here your bot github username
@password="" # Put here your bot github password

@repository="logstash/logstash"
@mention="@jordansissel"

@missing_changelog_message = <<MISSING_CHANGELOG
Hello, I'm #{@bot}, I'm here to help you accomplish your pull request submission quest

You still need to accomplish these tasks:

* Please add a changelog information

Also note that your pull request name will appears in the details section 
of the release notes, so please make it clear
MISSING_CHANGELOG

@ok_changelog_message = <<OK_CHANGELOG
You successfully completed the pre-requisite quest (aka updating CHANGELOG)

Also note that your pull request name will appears in the details section 
of the release notes, so please make it clear, if not already done.

#{@mention} Dear master, would you please have a look to this humble request
OK_CHANGELOG

#Connect to Github
@client=Octokit::Client.new(:login => @bot, :password => @password)


#For each open pull
Octokit.pull_requests(@repository).each do |pull|
  #Get botComment
  botComment = nil
  @client.issue_comments(@repository, pull.number, {
    :sort => "created",
    :direction => "desc"
  }).each do |comment|
    if comment.user.login == @bot
      botComment = comment
      break
    end
  end

  if !botComment.nil? and botComment.body.start_with?("[BOT-OK]")
    #Pull already validated by bot, nothing to do
    puts "Pull request #{pull.number}, already ok for bot"
  else
    #Firt encounter, or previous [BOT-WARN] status
    #Check for changelog
    warnOnMissingChangeLog = true
    @client.pull_request_files(@repository, pull.number).each do |changedFile|
      if changedFile.filename  == "CHANGELOG"
        if changedFile.additions.to_i > 0
          #Changelog looks good
          warnOnMissingChangeLog = false
        else
          #No additions, means crazy deletion
          warnOnMissingChangeLog = true
        end
      end
    end
    if warnOnMissingChangeLog
      if botComment.nil?
        puts "Pull request #{pull.number}, adding bot warning"
        @client.add_comment(@repository, pull.number, "[BOT-WARN] #{@missing_changelog_message}")
      else
        puts "Pull request #{pull.number}, already warned, no changes yet"
      end
    else
      if !botComment.nil?
        @client.delete_comment(@repository,botComment.id)
      end
      puts "Pull request #{pull.number}, adding bot ok"
      @client.add_comment(@repository, pull.number, "[BOT-OK] #{@ok_changelog_message}")
    end
  end
end
