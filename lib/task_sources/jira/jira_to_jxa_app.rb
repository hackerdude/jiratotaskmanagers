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

# Ask for 100 items at a time (JIRA default is 50). It's not that much RAM.
JIRA_MAX_RESULTS = 100

require 'rubygems'
require 'getoptlong'
require 'yaml'
require 'jira'
require 'json'
require File.join(File.dirname(__FILE__), '../../config_store')

class JiraToJxaApp

  def initialize
    @config_filename = CONFIG_STORE_OPTIONS[:config_store]
  end

  def usage
    puts "Usage: #{$0} [--clear-config|-c] [--print-config|-p] [--config-file|-f]"
  end

  def print_config
    config_store = ConfigStore.new(CONFIG_STORE_OPTIONS)
    puts <<-EOF
  ** Current Config:

  JIRA:
   Username: #{config_store.username}
   Password: #{'*' * config_store.password.length }
   JIRA Uri: #{config_store.jira_url}

  Task App:
  EOF
    config_store.task_app_params.each do |param, value|
      puts " #{param}: #{value}"
    end
    puts "\n"
  end

  def opt_parse
    @config_filename = CONFIG_STORE_OPTIONS[:config_store]
    # Parse command line arguments
    begin
      opts = GetoptLong.new(
        ["--clear-config", "-C", GetoptLong::OPTIONAL_ARGUMENT],
        ["--print-config", "-p", GetoptLong::OPTIONAL_ARGUMENT],
        ["--help",         "-h", GetoptLong::OPTIONAL_ARGUMENT],
        ["--config-file",  "-f", GetoptLong::OPTIONAL_ARGUMENT]
      )
    rescue => e
      usage()
      exit
    end

    opts.each do |opt, arg|
      case opt
        when '--help'
          usage
          exit 2
        when '--config-file'
          @config_filename = arg
        when '--print-config'
          print_config
          exit 5
        when '--clear-config'
          begin
            File.unlink(@config_filename) if File.exist?(@config_filename)
            puts "Cleared config from #{@config_filename}"
          rescue => e
            puts "Clearing config info from #{@config_filename} FAILED:"
            raise
          end
      end # case
    end
  end

  def main
    opt_parse
    if ! @config_filename.blank?
      puts "Config: #{@config_filename}"
      CONFIG_STORE_OPTIONS[:config_store] = @config_filename
    end
    config_store = ConfigStore.new(CONFIG_STORE_OPTIONS)
    # Connect to JIRA
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

    report_results = []
    this_page = jira_client.Issue.jql(config_store.jira_query, {:max_results=>JIRA_MAX_RESULTS})
    page = 0
    until this_page.length == 0 do
      puts " - Pg: #{page+=1}"
      report_results.concat(this_page)
      this_page = jira_client.Issue.jql(config_store.jira_query, { :max_results=>JIRA_MAX_RESULTS, :start_at => report_results.length })
    end

    # puts "Got #{report_results.length} items"
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
      things_jxa = File.join(File.dirname(__FILE__), 'task_destinations', JXA_FILE)

      output = `#{things_jxa} #{file.path}`
      output.split("\n").each do |line|
        puts "[parent] output: #{line}"
      end
    rescue => e
      puts "Error - #{e.message}"
    end

    file.unlink
  end

end