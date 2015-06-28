# JIRA To Task Managers

## JIRA To Things

Requires Yosemite because it uses JXA.

You may need to use rvm to install a newer ruby. I use 2.1.5, and it's in the Gemfile.

``
$ bundle install
$ ./jiratothings                                                                                           1 ↵
JIRA Url: (enter your https Jira URL - OnDemand works fine)
User name: (your jira user name)
Password:
Store password? (y/n) y
assignee = currentUser() order by priority desc
Storing password
Storing on /Users/yourname/.jiratoomnifocus/jira_credentials.yml

Running a bit of JXA AppleScript..
Finished updating N tasks in Things.
``

You are set up! Now you can put it on a cron line, like this one which sets it to run at office
hours (use `crontab -e` in Terminal for this):

    */10 7-18 * * * /yourdir/jiratothings > /yourdir/log/jira_to_omnifocus.log 2>&1

Congratulations!  You are done.


## JIRA To Omnifocus

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

You are set up! Now you can put it on a cron line, like this one which sets it to run at office
hours (use `crontab -e` in Terminal for this):

    */10 7-18 * * * /yourdir/jiratoomnifocus > /yourdir/log/jira_to_omnifocus.log 2>&1

Congratulations!  You are done.

### Security Warning
The password for your JIRA account will be saved on a file on your computer called
`~/.jiratoomnifocus/jira_credentials.yml`. It is encrypted using blowfish using a constant key.

As long as both your jiratoomnifocus script and your credentials file are secured as (chmod 700 and
owned by the user that will be running it on cron), you should be okay and secure (unless someone
breaks into your account, in which case you have bigger problems than your JIRA access!).

### License
    Copyright 2009, David Martinez
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
       http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
