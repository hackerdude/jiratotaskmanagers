require 'crypt/blowfish'
require 'crypt/cbc'
require 'fileutils'

# Encrypted config store
class ConfigStore

  Param = Struct.new("Param", :name, :title, :default)

  STORE_FOLDER           ="#{ENV['HOME']}/.jiratotaskmanagers"
  DEFAULT_CONFIG_STORE    ="#{STORE_FOLDER}/jira_credentials.yml"
  # Change this key and run jiratothings -C to clear the login
  CRYPT_KEY              = ENV['JIRA_TO_TASKS_CRYPT_KEY'] || "70C13D0C-E89E-47B4-BEC9-1126CBF3C9FB"

  DEFAULT_JIRA_QUERY = "assignee = currentUser() order by priority desc"

  # JIRA Config Stuff
  attr_reader :jira_url, :jira_query
  attr_reader :username, :password

  attr_reader :task_app_params

  # Did they say we could store the config?
  attr_reader :store

  # Other options
  attr_reader :options

  def initialize(options)
    @options = options
    @config_store = @options[:config_store] || DEFAULT_CONFIG_STORE
    # Task App params
    @task_app_params = {}
    @crypt = Crypt::Blowfish.new(CRYPT_KEY)
    if (File.exists?(@config_store))
      # Get the password from the credentials file
      read_config
    else
      read_from_stdin
    end
  end

  # TODO This probably does not belong here.
  def create_jira_connection
    @connection ||= JIRA::Client.new({
      :username => @username,
      :password => @password,
      :site     => @jira_url,
      :context_path => '',
      :auth_type => :basic,
      :use_ssl => true
    })
  end

  def test_jira_connection
     jira_client = create_jira_connection
     jira_client.Issue.jql(jira_query, {:max_results=>1})
  end

  def ask_question(question, default='', hide_question=false)
    print question
    $stdout.flush
    system "stty -echo" if hide_question
    result = answered = STDIN.gets.chomp!
    if ! answered || answered == ''
      result = default || ''
    end
    system "stty echo" if hide_question
    result
  end

  def read_from_stdin
    @connection_ok = false
    while (! @connection_ok)      
      @jira_url = ask_question("JIRA Url (usually https://yourdomain.atlassian.net):", @jira_url)
      @jira_query = ask_question("JIRA Query ([Enter] for #{DEFAULT_JIRA_QUERY} ): ", @jira_query || DEFAULT_JIRA_QUERY)


      @username = ask_question("JIRA Username:", @username)
      @password=  ask_question("JIRA Password: ", @password, true)

      print "Testing JIRA connection.. "
      begin
        test_jira_connection
      rescue => e
        puts "\nJIRA Connection failed (#{e.message}).
        \nPlease answer the questions again.
        \nPressing [Enter] keeps your previous answers."
      end
    end

    puts "\n\n** Task App Config"

    @options[:task_app_params].each do |param|
      prompt = "\n#{param.title}"
      prompt+= " ([Enter] for #{param.default})" unless param.default.nil? || param.default == ''

      print "#{prompt}: "
      $stdout.flush
      @task_app_params[param.name]=STDIN.gets.chomp!
      if @task_app_params[param.name] == '' && ! param.default.nil?
        @task_app_params[param.name] = param.default
      end
    end

    print "\nStore config? (y/n) "
    @store = STDIN.gets.chomp! == "y"
  end

  def store_config
    puts "Storing config " if @store
    puts "Storing on #{@config_store}"
    folder = File.dirname(@config_store)
    FileUtils.mkdir_p folder
    open("#{@config_store}", "w") do |f|
      # Block cypher with 8 char blocksize
      f.puts @crypt.encrypt_string(YAML::dump({
        :username => @username, :password =>@password,
        :jira_url => @jira_url, :task_app_params=> @task_app_params,
        :jira_query => @jira_query
      }))
    end
  end

  def read_config
    @payload = nil
    open("#{@config_store}", "r") do |f|
      crypted = f.read.chomp!
      @payload = YAML::load(@crypt.decrypt_string(crypted))
    end
    @username = @payload[:username].chomp
    @password = @payload[:password].chomp
    @jira_url = @payload[:jira_url].chomp
    @jira_query = @payload[:jira_query].chomp
    @task_app_params = @payload[:task_app_params]
    @store = false
  end
end
