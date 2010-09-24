# Work in progress #

This project is still in development. I am still tweaking the APIs on a regular basis. Please avoid using this gem unless you are okay with changing APIs.

The latest version on rubygems.org is v0.0.1.

# Examples #

## Print out all issue keys, their available actions, and the fields you can edit with the first action available

	require 'better_jira'

	ALL_ISSUES_FILTER_ID = 33323
	

	jira = BetterJira::Jira.new
	jira.login('usename', 'password')
	
	jira.each_issue_from_filter(ALL_ISSUES_FILTER_ID) { |issue|
		puts "- Found issue #{issue[:key]}"
		puts "Actions: "
		actions = issue.available_actions # Connects to server to get actions
		pp actions
		puts ""
		puts "Fields for action #{actions.first.to_s}:"
		pp jira.fields_for_action_id(actions.first[0])
	}