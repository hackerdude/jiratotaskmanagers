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
JIRA_STATI_FOR_COMPLETED=["Resolved", "Rejected", "Closed"] # The status a completed JIRA project should have on your machine.

require 'rubygems'
require 'getopt/long'
require 'yaml'
require 'jira'
require 'json'
require File.join(File.dirname(__FILE__), 'config_store')

# require 'byebug' ; Debugger.start if defined? Debugger

def usage
  puts "Usage: jiratothings [--clear-config|-c]"
end

def main ()
  # Parse command line arguments
  begin
    opt = Getopt::Long.getopts ["--clear-config", "-C", Getopt::BOOLEAN]
  rescue
    usage()
    exit
  end

  # If -C or --clear-config passed, clear login info from stored password file
  if opt["clear-config"]
    begin
      config_store_filename = CONFIG_STORE_OPTIONS[:config_store]
      File.unlink(config_store_filename) if File.exist?(config_store_filename)
      puts "Cleared config from #{config_store_filename}"
    rescue => e
      puts "Clearing config info from #{config_store_filename} FAILED:"
      raise
    end
  end

  # Connect to JIRA
  config_store = ConfigStore.new(CONFIG_STORE_OPTIONS)
  jira_client = JIRA::Client.new({
                :username => config_store.username,
                :password => config_store.password,
                :site     => config_store.jira_url,
                :context_path => '',
                :auth_type => :basic
  })

  # Get issues from saved filter
  puts "Running JQL:"
  puts config_store.jira_query
  report_results = jira_client.Issue.jql(config_store.jira_query)

  # Only store the password when login went ok
  config_store.store_config unless ! config_store.store

  if report_results.nil? || report_results.length == 0
    puts "No results from JIRA report"
    exit
  end

  output = {
    :results=>[],
    :completed_stati => JIRA_STATI_FOR_COMPLETED,
    :task_app_params => config_store.task_app_params
  }

  # Iterate through resulting issues.
  report_results.each do |row|
    jira_id = row.key
    title   = row.summary
    description = row.description
    task_name = "#{jira_id}: #{title}"
    task_notes = "#{config_store.jira_url}/browse/#{jira_id}\n#{description}"

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
    things_jxa = File.join(File.dirname(__FILE__), 'backends', JXA_FILE)

    output = `#{things_jxa} #{file.path}`
    output.split("\n").each do |line|
      puts "[parent] output: #{line}"
    end
  rescue => e
    puts "Error - #{e.message}"
  end

  file.unlink


end
