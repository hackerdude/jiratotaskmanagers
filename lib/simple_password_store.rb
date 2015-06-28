require 'crypt/blowfish'
require 'crypt/cbc'

# A Simple Password Store
class SimplePasswordStore
  STORE_FOLDER           ="#{ENV['HOME']}/.jiratotaskmanagers"
  DEFAULT_PASSWORD_STORE ="#{STORE_FOLDER}/jira_credentials.yml"
  # Change this key and run jiratothings -C to clear the login
  CRYPT_KEY              = ENV['JIRA_TO_TASKS_CRYPT_KEY'] || "djkhsfoiu345jknrjvxy87345jlhk3bnmkvcxljhulhHENPJdT"

  DEFAULT_JIRA_QUERY = "assignee = currentUser() order by priority desc"

  attr_reader :jira_url, :jira_query, :project_name
  attr_reader :username, :password, :store

  attr_reader :options

  def initialize(options)
    @options = options
    @password_store = @options[:password_store] || DEFAULT_PASSWORD_STORE
    @crypt = Crypt::Blowfish.new(CRYPT_KEY)
    if (File.exists?@password_store)
      # Get the password from the credentials file
      read_password
    else
      read_from_stdin
    end
  end

  def read_from_stdin
    print "JIRA Url (usually https://yourdomain.atlassian.net):"
    $stdout.flush
    @jira_url=STDIN.gets.chomp!

    print "JIRA Query (leave blank to use #{DEFAULT_JIRA_QUERY} ): "
    $stdout.flush
    @jira_query=STDIN.gets.chomp!
    if @jira_query == ''
      @jira_query = DEFAULT_JIRA_QUERY
    end

    print "Project Name on your Mac's To Do App: "
    $stdout.flush
    @project_name=STDIN.gets.chomp!

    print "User name: "
    $stdout.flush
    @username=STDIN.gets.chomp!

    print "Password: "
    $stdout.flush
    system "stty -echo"
    @password=STDIN.gets.chomp!
    system "stty echo"
    print "\nStore config? (y/n) "
    @store = STDIN.gets.chomp! == "y"
  end

  def store_password
    puts "Storing password " if @store
    puts "Storing on #{@password_store}"
    FileUtils.mkdir_p STORE_FOLDER
    open("#{@password_store}", "w") do |f|
      # Block cypher with 8 char blocksize
      f.puts @crypt.encrypt_string(YAML::dump({ 
        :username => @username, :password =>@password,
        :jira_url => @jira_url, :project_name=> @project_name,
        :jira_query => @jira_query
      }))
    end
  end

  def read_password
    @payload = nil
    open("#{@password_store}", "r") do |f|
      crypted = f.read.chomp!
      @payload = YAML::load(@crypt.decrypt_string(crypted))
    end
    @username = @payload[:username].chomp
    @password = @payload[:password].chomp
    @jira_url = @payload[:jira_url].chomp
    @jira_query = @payload[:jira_query].chomp
    @project_name = @payload[:project_name].chomp
    @store = false
  end
end
