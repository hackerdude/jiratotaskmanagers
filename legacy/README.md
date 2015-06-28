# JIRA To Omnifocus (Legacy)

The original blog post for this is [here](http://www.hackerdude.com/2009/03/04/jira-to-omnifocus-script/)

__Please note that Ruby 1.8.7 is required!  At the present moment the rb-appscript gem does NOT work
on Ruby 1.9.2.__

This script logs into your JIRA and creates OmniFocus tasks for each of the JIRA items that are
assigned to you, so they sync to your Omnifocus for iPhone, you only have to keep track of one
inbox, etc. It only takes a tiny bit of setup.

###Installation
To set this up, do the following:

* Clone the repo: `git clone https://github.com/afazio/jiratoomnifocus.git`
* Install the required gems: `gem install rb-appscript crypt password getopt activesupport`
* Go to JIRA and create a saved filter with whatever settings you like. Note the filter
  ID. (A.K.A. requestId)
* Edit the `jiratoomnifocus` script and set `JIRA_FILTER_ID` to the filter ID described above.
  Also, set `JIRA_BASE_URL` to the URL of your JIRA installation.
* If you like to keep your system very secure, take a look at the security warning below.
* Run the script. You will be asked to login the first time. After it is done, note the new tasks on
  your Omnifocus. Delete a task and run it again to see it add it again without asking you for
  authentication.

# Scheduling your task

Once you've run it once successfully, you can put it on a cron line, like this one which sets the jiratoomnifocus script to run at office hours (use `crontab -e` in Terminal for this):

    */10 7-18 * * * /yourdir/jirato(yourtaskapp) > /yourdir/log/jira_to_(yourtaskapp).log 2>&1

Congratulations!  You are done.

