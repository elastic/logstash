require "test_utils"
require "logstash/filters/prune"

describe LogStash::Filters::Prune do
  extend LogStash::RSpec

  describe "defaults" do

    config <<-CONFIG
      filter {
        prune { }
      }
    CONFIG
    
    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == "Borat"
      insist { subject["lastname"] } == "Sagdiyev"
      insist { subject["fullname"] } == "Borat Sagdiyev"
      insist { subject["country"] } == "Kazakhstan"
      insist { subject["location"] } == "Somethere in Kazakhstan"
      insist { subject["hobby"] } == "Cloud"
      insist { subject["status"] } == "200"
      insist { subject["Borat_saying"] } == "Cloud is not ready for enterprise if is not integrate with single server running Active Directory."
      insist { subject["%{hmm}"] } == nil
    end
  end

  describe "whitelist field names" do

    config <<-CONFIG
      filter {
        prune {
          whitelist_names => [ "firstname", "(hobby|status)", "%{firstname}_saying" ]
        }
      }
    CONFIG
    
    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == "Borat"
      insist { subject["lastname"] } == nil
      insist { subject["fullname"] } == nil
      insist { subject["country"] } == nil
      insist { subject["location"] } == nil
      insist { subject["hobby"] } == "Cloud"
      insist { subject["status"] } == "200"
      insist { subject["Borat_saying"] } == nil
      insist { subject["%{hmm}"] } == nil
    end
  end

  describe "whitelist field names with interpolation" do

    config <<-CONFIG
      filter {
        prune {
          whitelist_names => [ "firstname", "(hobby|status)", "%{firstname}_saying" ]
          interpolate     => true
        }
      }
    CONFIG
    
    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == "Borat"
      insist { subject["lastname"] } == nil
      insist { subject["fullname"] } == nil
      insist { subject["country"] } == nil
      insist { subject["location"] } == nil
      insist { subject["hobby"] } == "Cloud"
      insist { subject["status"] } == "200"
      insist { subject["Borat_saying"] } == "Cloud is not ready for enterprise if is not integrate with single server running Active Directory."
      insist { subject["%{hmm}"] } == nil
    end
  end

  describe "blacklist field names" do

    config <<-CONFIG
      filter {
        prune {
          blacklist_names => [ "firstname", "(hobby|status)", "%{firstname}_saying" ]
        }
      }
    CONFIG

    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == nil
      insist { subject["lastname"] } == "Sagdiyev"
      insist { subject["fullname"] } == "Borat Sagdiyev"
      insist { subject["country"] } == "Kazakhstan"
      insist { subject["location"] } == "Somethere in Kazakhstan"
      insist { subject["hobby"] } == nil
      insist { subject["status"] } == nil
      insist { subject["Borat_saying"] } == "Cloud is not ready for enterprise if is not integrate with single server running Active Directory."
      insist { subject["%{hmm}"] } == "doh"
    end
  end

  describe "blacklist field names with interpolation" do

    config <<-CONFIG
      filter {
        prune {
          blacklist_names => [ "firstname", "(hobby|status)", "%{firstname}_saying" ]
          interpolate     => true
        }
      }
    CONFIG

    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == nil
      insist { subject["lastname"] } == "Sagdiyev"
      insist { subject["fullname"] } == "Borat Sagdiyev"
      insist { subject["country"] } == "Kazakhstan"
      insist { subject["location"] } == "Somethere in Kazakhstan"
      insist { subject["hobby"] } == nil
      insist { subject["status"] } == nil
      insist { subject["Borat_saying"] } == nil
      insist { subject["%{hmm}"] } == "doh"
    end
  end

  describe "whitelist field values" do

    config <<-CONFIG
      filter {
        prune {
          whitelist_values => [ "firstname", "^Borat$",
                                "fullname", "%{firstname} Sagdiyev",
                                "location", "no no no",
                                "status", "^2",
                                "%{firstname}_saying", "%{hobby}.*Active" ]
        }
      }
    CONFIG

    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == "Borat"
      insist { subject["lastname"] } == "Sagdiyev"
      insist { subject["fullname"] } == nil
      insist { subject["country"] } == "Kazakhstan"
      insist { subject["location"] } == nil
      insist { subject["hobby"] } == "Cloud"
      insist { subject["status"] } == "200"
      insist { subject["Borat_saying"] } == "Cloud is not ready for enterprise if is not integrate with single server running Active Directory."
      insist { subject["%{hmm}"] } == nil
    end
  end

  describe "whitelist field values with interpolation" do

    config <<-CONFIG
      filter {
        prune {
          whitelist_values => [ "firstname", "^Borat$",
                                "fullname", "%{firstname} Sagdiyev",
                                "location", "no no no",
                                "status", "^2",
                                "%{firstname}_saying", "%{hobby}.*Active" ]
          interpolate      => true
        }
      }
    CONFIG

    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == "Borat"
      insist { subject["lastname"] } == "Sagdiyev"
      insist { subject["fullname"] } == "Borat Sagdiyev"
      insist { subject["country"] } == "Kazakhstan"
      insist { subject["location"] } == nil
      insist { subject["hobby"] } == "Cloud"
      insist { subject["status"] } == "200"
      insist { subject["Borat_saying"] } == "Cloud is not ready for enterprise if is not integrate with single server running Active Directory."
      insist { subject["%{hmm}"] } == nil
    end
  end

  describe "blacklist field values" do

    config <<-CONFIG
      filter {
        prune {
          blacklist_values => [ "firstname", "^Borat$",
                                "fullname", "%{firstname} Sagdiyev",
                                "location", "no no no",
                                "status", "^2",
                                "%{firstname}_saying", "%{hobby}.*Active" ]
        }
      }
    CONFIG

    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == nil
      insist { subject["lastname"] } == "Sagdiyev"
      insist { subject["fullname"] } == "Borat Sagdiyev"
      insist { subject["country"] } == "Kazakhstan"
      insist { subject["location"] } == "Somethere in Kazakhstan"
      insist { subject["hobby"] } == "Cloud"
      insist { subject["status"] } == nil
      insist { subject["Borat_saying"] } == "Cloud is not ready for enterprise if is not integrate with single server running Active Directory."
      insist { subject["%{hmm}"] } == nil
    end
  end

  describe "blacklist field values with interpolation" do

    config <<-CONFIG
      filter {
        prune {
          blacklist_values => [ "firstname", "^Borat$",
                                "fullname", "%{firstname} Sagdiyev",
                                "location", "no no no",
                                "status", "^2",
                                "%{firstname}_saying", "%{hobby}.*Active" ]
          interpolate      => true
        }
      }
    CONFIG

    sample(
      "firstname"    => "Borat",
      "lastname"     => "Sagdiyev",
      "fullname"     => "Borat Sagdiyev",
      "country"      => "Kazakhstan",
      "location"     => "Somethere in Kazakhstan",
      "hobby"        => "Cloud",
      "status"       => "200",
      "Borat_saying" => "Cloud is not ready for enterprise if is not integrate with single server running Active Directory.",
      "%{hmm}"       => "doh"
    ) do
      insist { subject["firstname"] } == nil
      insist { subject["lastname"] } == "Sagdiyev"
      insist { subject["fullname"] } == nil
      insist { subject["country"] } == "Kazakhstan"
      insist { subject["location"] } == "Somethere in Kazakhstan"
      insist { subject["hobby"] } == "Cloud"
      insist { subject["status"] } == nil
      insist { subject["Borat_saying"] } == nil
      insist { subject["%{hmm}"] } == nil
    end
  end

  describe "whitelist field values on fields witn array values" do

    config <<-CONFIG
      filter {
        prune {
          whitelist_values => [ "status", "^(1|2|3)",
                                "xxx", "3",
                                "error", "%{blah}" ]
        }
      }
    CONFIG

    sample(
      "blah"   => "foo",
      "xxx" => [ "1 2 3", "3 4 5" ],
      "status" => [ "100", "200", "300", "400", "500" ],
      "error"  => [ "This is foolish" , "Need smthing smart too" ]
    ) do
      insist { subject["blah"] } == "foo"
      insist { subject["error"] } == nil
      insist { subject["xxx"] } == [ "1 2 3", "3 4 5" ]
      insist { subject["status"] } == [ "100", "200", "300" ]
    end
  end

  describe "blacklist field values on fields witn array values" do

    config <<-CONFIG
      filter {
        prune {
          blacklist_values => [ "status", "^(1|2|3)",
                                "xxx", "3",
                                "error", "%{blah}" ]
        }
      }
    CONFIG

    sample(
      "blah"   => "foo",
      "xxx" => [ "1 2 3", "3 4 5" ],
      "status" => [ "100", "200", "300", "400", "500" ],
      "error"  => [ "This is foolish", "Need smthing smart too" ]
    ) do
      insist { subject["blah"] } == "foo"
      insist { subject["error"] } == [ "This is foolish", "Need smthing smart too" ]
      insist { subject["xxx"] } == nil
      insist { subject["status"] } == [ "400", "500" ]
    end
  end

  describe "whitelist field values with interpolation on fields witn array values" do
 
    config <<-CONFIG
      filter {
        prune {
          whitelist_values => [ "status", "^(1|2|3)",
                                "xxx", "3",
                                "error", "%{blah}" ]
          interpolate      => true
        }
      }
    CONFIG

    sample(
      "blah"   => "foo",
      "xxx" => [ "1 2 3", "3 4 5" ],
      "status" => [ "100", "200", "300", "400", "500" ],
      "error"  => [ "This is foolish" , "Need smthing smart too" ]
    ) do
      insist { subject["blah"] } == "foo"
      insist { subject["error"] } == [ "This is foolish" ]
      insist { subject["xxx"] } == [ "1 2 3", "3 4 5" ]
      insist { subject["status"] } == [ "100", "200", "300" ]
    end
  end

  describe "blacklist field values with interpolation on fields witn array values" do

    config <<-CONFIG
      filter {
        prune {
          blacklist_values => [ "status", "^(1|2|3)",
                                "xxx", "3",
                                "error", "%{blah}" ]
          interpolate      => true
        }
      }
    CONFIG

    sample(
      "blah"   => "foo",
      "xxx" => [ "1 2 3", "3 4 5" ],
      "status" => [ "100", "200", "300", "400", "500" ],
      "error"  => [ "This is foolish" , "Need smthing smart too" ]
    ) do
      insist { subject["blah"] } == "foo"
      insist { subject["error"] } == [ "Need smthing smart too" ]
      insist { subject["xxx"] } == nil
      insist { subject["status"] } == [ "400", "500" ]
    end
  end

end
