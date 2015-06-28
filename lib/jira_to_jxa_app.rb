#   Copyright 2009, David Martinez <david@hackerdude.com>
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# Change the filter id here. TODO Use by name and save it on the config.
JIRA_TASK_RE=/(.*-[0-9]*):(.*)/
JIRA_STATI_FOR_COMPLETED=["Resolved", "Closed"] # The status a completed JIRA project should have on your machine.

require 'rubygems'
require 'getopt/long'
require 'yaml'
require 'jira'
require 'json'
require File.join(File.dirname(__FILE__), 'simple_config_store')

# require 'byebug' ; Debugger.start if defined? Debugger

def usage
  puts "Usage: jiratothings [--clear-login|-c]"
end

def main ()
  # Parse command line arguments
  begin
    opt = Getopt::Long.getopts ["--clear-login", "-C", Getopt::BOOLEAN]
  rescue
    usage()
    exit
  end

  # If -C or --clear-login passed, clear login info from stored password file
  if opt["clear-login"]
    begin
      File.unlink(CONFIG_STORE_OPTIONS[:config_store]) if File.exist?(CONFIG_STORE_OPTIONS[:config_store])
      puts "Cleared login from #{CONFIG_STORE_OPTIONS[:config_store]}"
    rescue => e
      puts "Clearing login info from #{CONFIG_STORE_OPTIONS[:config_store]} FAILED:"
      raise
    end
  end

  # Connect to OmniFocus and Jira
  # TODO Different backends may have different options. Pass options from backend.
  password_store = SimpleConfigStore.new(CONFIG_STORE_OPTIONS)
  jira_client = JIRA::Client.new({
                :username => password_store.username,
                :password => password_store.password,
                :site     => password_store.jira_url,
                :context_path => '',
                :auth_type => :basic
  })

  # Get issues from saved filter
  puts "Running JQL:"
  puts password_store.jira_query
  report_results = jira_client.Issue.jql(password_store.jira_query)

  # Only store the password when login went ok
  password_store.store_password unless ! password_store.store
  
  if report_results.nil? || report_results.length == 0
    puts "No results from JIRA report"
    exit
  end

  output = {
    :results=>[],
    :completed_stati => JIRA_STATI_FOR_COMPLETED,
    :default_project => password_store.project_name
  }

  # Iterate through resulting issues.
  report_results.each do |row|
    jira_id = row.key
    title   = row.summary
    description = row.description
    task_name = "#{jira_id}: #{title}"
    task_notes = "#{password_store.jira_url}/browse/#{jira_id}\n#{description}"
    
    priority = row.priority
    priority_value = priority.nil? ? 99 : priority.id.to_i
    flagged = priority_value <= 3 ? true : false
    status = row.status.name
    output[:results] << {
      :task_name =>  task_name,
      :task_notes => task_notes,
      :status =>     status,
      :task_flagged => flagged
    }

  end # report_results.each

  puts "Got #{output[:results].length} issues that we'll sync with your app"

  # puts "\nWriting to JSON temp file"
  file = Tempfile.new("jira-tasks")
  file.write(JSON.generate(output))
  file.close

  begin
    puts "\nRunning #{JXA_FILE}"
    things_jxa = File.join(File.dirname(__FILE__), JXA_FILE)
    
    output = `#{things_jxa} #{file.path}`
    output.split("\n").each do |line|
      puts "[parent] output: #{line}"
    end
  rescue => e
    puts "Error - #{e.message}"
  end
  
  file.unlink
  
  
end
