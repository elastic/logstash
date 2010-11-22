Feature: multiline filter
  In order to ensure multiline filter is working
  Events matching the multiline filter should be joined

  Scenario: whitespace-leading lines (like java stack traces)
    Given a multiline pattern of "^\s"
      And a multiline what of "previous"
    # We use quotes wrap lines here because cucumber will trim the whitespace
    # otherwise
    When the inputs are
      |hello world|
      |"   continued!"|
      |one|
      |two|
      |"   two again"|
    Then the event message should be
      |hello world\n   continued!|
      |one|
      |two\n   two again|

  Scenario: '...' continuation with next
    Given a multiline pattern of "\.\.\.$"
      And a multiline what of "next"
    # We use quotes wrap lines here because cucumber will trim the whitespace
    # otherwise
    When the inputs are
      |hello world... |
      |"   continued!"|
      |one|
      |two...|
      |"   two again"|
    Then the event message should be
      |hello world...\n   continued!|
      |one|
      |two...\n   two again|
