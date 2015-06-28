# JIRA To Task Managers

This is a project to have JIRA update AppleScript-enabled Task apps like Omnifocus and Things.

Requires Yosemite because it uses JXA.

Supported Task Apps:

- Omnifocus
- Things

## Why?

If you are a fan of David Allen's [GTD](http://gettingthingsdone.com/ "Getting Things Done"), you probably know how important it is to have only "One Inbox". Many people use something that syncs everywhere, such as Omnifocus or Things.

However for collaboration with others, many techies use [Atlassian JIRA] (https://www.atlassian.com/software/jira "Atlassian JIRA Product page"). This ends up in a weird "two inboxes" problems, that forces us to schedule our coding life separate from our non-coding life (both work and play).

This I believe leads to tremendous life imbalances. Do I code now, or do I write docs (which are not in JIRA)? On my "What's Next", are my coding tasks included?

JIRA To Task managers is a set of scripts that you can schedule on your Mac, which create one task for each of your assigned JIRA tasks. You can use cron to "set it and forget it", and get back to *One Inbox Bliss*.

If you're a coder, and you use a different (scriptable) task manager on your Mac, I invite you to code a backend (see below). JXA can be fun!

## Setting Up

This shows the setup for [Things](https://culturedcode.com/things/). They all work the same, just run the jirato(yourproject) instead.

Some projects may ask slightly different questions.

You may need to use rvm to install a newer ruby. I use 2.1.5, and it's what's specified in the Gemfile.

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


## Adding it to Cron

You are set up! Now you can put it on a cron line, like this one which sets it to run at office
hours (use `crontab -e` in Terminal for this):

    */10 7-18 * * * /yourdir/jiratothings > /yourdir/log/jira_to_omnifocus.log 2>&1

Congratulations!  You are done.


### Security Warning

The password for your JIRA account will be saved on a file on your computer called
`~/.jiratoomnifocus/jira_credentials.yml`. It is encrypted using blowfish using a constant key.

As long as both your jiratoomnifocus script and your credentials file are secured as (chmod 700 and
owned by the user that will be running it on cron), you should be okay and secure (unless someone
breaks into your account, in which case you have bigger problems than your JIRA access!).

If this bothers you, you can set the environment variable `JIRA_TO_TASKS_CRYPT_KEY` to have the configuration store use a different key. You will need to run -C to clear the config that uses the old key.

## How to add New Backends

So you have Super-Duper app and you want to add support for it? With JXA, this is now fairly simple to do. JXA is just like JavaScript, and you have our template here.

1. Copy lib/add_to_things.jxa and edit it.

	Start by changing TaskApp = Application("Things") to match the app you want to work with. Use Applescript Editor (or Textmate with [AppleScript JXA Bundle](https://github.com/hackerdude/AppleScript-JXA.tmbundle)) and a sample JSON file, or just finish the rest of the changes and do trial-and-error with your own app.
1. Copy `jiratothings` to jirato(yourapp)
1. change the `JXA_FILE` constant to point to your jxa file, and the `CONFIG_STORE_OPTIONS` to point to the config file you want to keep.
1. If you need extra configuration ("contexts, tags, oh my!"), add `ConfigStore::Param` entries to the `task_app_params` array (as you test, use -C to clear the config whenever you change it)

Try it out and you're done! Send me a pull request and I'll accept it.


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
