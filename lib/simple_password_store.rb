require 'crypt/blowfish'
require 'crypt/cbc'

# A Simple Password Store
class SimplePasswordStore
  HACKERDUDE_TOOLS_DIR="#{ENV['HOME']}/.jiratoomnifocus"
  DEFAULT_PASSWORD_STORE="#{HACKERDUDE_TOOLS_DIR}/jira_credentials.yml"

  attr_reader :jira_url
  attr_reader :project_name

  attr_reader :username, :password, :store

  attr_reader :options

  def initialize(options)
    @options = options
    @crypt = Crypt::Blowfish.new(CRYPT_KEY)
    if (File.exists?DEFAULT_PASSWORD_STORE)
      # Get the password from the credentials file
      read_password
    else
      read_from_stdin
    end
  end

  def read_from_stdin
    print "JIRA Url: "
    $stdout.flush
    @jira_url=STDIN.gets.chomp!

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
    print "\nStore password? (y/n) "
    @store = STDIN.gets.chomp! == "y"
  end

  def store_password
    puts "Storing password " if @store
    puts "Storing on #{DEFAULT_PASSWORD_STORE}"
    FileUtils.mkdir_p HACKERDUDE_TOOLS_DIR
    open("#{DEFAULT_PASSWORD_STORE}", "w") do |f|
      # Block cypher with 8 char blocksize
      f.puts @crypt.encrypt_string(YAML::dump({ 
        :username => @username, :password =>@password,
        :jira_url => @jira_url, :project_name=> @project_name
      }))
    end
  end

  def read_password
    @payload = nil
    open("#{DEFAULT_PASSWORD_STORE}", "r") do |f|
      crypted = f.read.chomp!
      @payload = YAML::load(@crypt.decrypt_string(crypted))
    end
    @username = @payload[:username].chomp
    @password = @payload[:password].chomp
    @jira_url = @payload[:jira_url].chomp
    @project_name = @payload[:project_name].chomp
    @store = false
  end
end
