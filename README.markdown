# JIRA To Task Managers

This is a project to have JIRA update project managers.

## Why?

If you are a fan of David Allen's [GTD](http://gettingthingsdone.com/ "Getting Things Done"), you probably know how important it is to have only "One Inbox". Many people use something that syncs everywhere, such as Omnifocus or Things.

However for collaboration with others, many techies use [Atlassian JIRA] (https://www.atlassian.com/software/jira "Atlassian JIRA Product page"). This ends up in a weird "two inboxes" problems, that forces us to schedule our coding life separate from our non-coding life (both work and play).

This I believe leads to tremendous life imbalances. Do I code now, or do I write docs (which are not in JIRA). On my "What's Next", are my coding tasks included?

JIRA To Task managers is a set of scripts that you can schedule on your Mac, which create one task for each of your assigned JIRA tasks. You can use cron to "set it and forget it", and get back to *One Inbox Bliss*.

## Setting Up

This shows the setup for [Things](https://culturedcode.com/things/). They all should (eventually) work very similar.

The first time you run it, it looks like this:

	(maybe RVM install or something..)
	$ bundle install
	(installs all your gems and goodies..)

	$ ./jiratothings -C
	Cleared login from /Users/yourname/.jiratotaskmanagers/jira_to_things.yml
	JIRA Url (usually https://yourdomain.atlassian.net): 
	    (you type your JIRA URI)
	JIRA Query (leave blank to use assignee = currentUser() order by priority desc ): 
	    (If you don't know JQL, blank should be fine)
	Project Name on your Mac's To Do App: 
	    (type the Project name in your Mac's TODO app)
	User name: 
	    (your JIRA user name.
			Note: If you use OAuth, you still have a user name mapping,
			it's in your profile view)
	Password:
	Store config? (y/n) y
	Running JQL:
	assignee = currentUser() order by priority desc
	Storing password
	Storing on /Users/yourname/.jiratotaskmanagers/jira_to_things.yml
	Got 50 issues that we'll sync with your app

After this, every time you run it it looks like this:

	Running add_to_things.jxa
	Finished updating 50 tasks in Things.
	$ ./jiratothings
	Running JQL:
	assignee = currentUser() order by priority desc
	Got 999 issues that we'll sync with your app

	Running add_to_things.jxa
	Finished updating 999 tasks in Things.


### JIRA To Things

Requires Yosemite because it uses JXA.

You may need to use rvm to install a newer ruby. I use 2.1.5, and it's in the Gemfile.

You are set up! Now you can put it on a cron line, like this one which sets it to run at office
hours (use `crontab -e` in Terminal for this):

    */10 7-18 * * * /yourdir/jiratothings > /yourdir/log/jira_to_omnifocus.log 2>&1

Congratulations!  You are done.


### JIRA To Omnifocus

This is by far the older of the two projects, and requires some extra lovin' to bring it up to speed with the new switchable backend stuff. It would be great if someone were to update this to be more like jiratothings (see "Adding a new script").


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

    */10 7-18 * * * /yourdir/jiratoomnifocus > /yourdir/log/jira_to_omnifocus.log 2>&1

Congratulations!  You are done.

### Security Warning
The password for your JIRA account will be saved on a file on your computer called
`~/.jiratoomnifocus/jira_credentials.yml`. It is encrypted using blowfish using a constant key.

As long as both your jiratoomnifocus script and your credentials file are secured as (chmod 700 and
owned by the user that will be running it on cron), you should be okay and secure (unless someone
breaks into your account, in which case you have bigger problems than your JIRA access!).

## How to add New Backends

So you have Super-Duper app and you want to add a new one? With JXA, this is now fairly simple to do.

1. Copy lib/add_to_things.jxa and edit it.

	Start by changing TaskApp = Application("Things") to match the app you want to work with. Use Applescript editor and a sample JSON file, or just do #2 below and trial-and-error with your own app.
1. Copy `jiratothings` to jirato(yourapp)
1. change the `JXA_FILE` constant to point to your jxa file, and the `CONFIG_STORE_OPTIONS` to point to the config file you want to keep.

You're done! Send me a pull request and I'll accept it.

If your To-Do app needs more configuration (I'm thinking Omnifocus' contexts), the proper way to do it would be to add a new list of what to ask for on the `CONFIG_STORE_OPTIONS` and teach SimpleConfigStore to add these (optional) new items to the configuration. That way nothing is hardcoded.

## License
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
