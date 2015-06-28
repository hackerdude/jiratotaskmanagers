# JIRA To Task Managers

This is a project to have JIRA update AppleScript-enabled Task apps like Omnifocus and Things.

Requires Yosemite because it uses JXA for ease of scripting.

Currently supported Task Apps:

- [Omnifocus 1 & 2](https://www.omnigroup.com/omnifocus)
- [Things 2](https://culturedcode.com/things/)
- [Apple Reminders](https://help.apple.com/reminders/mac/10.10/index.html?localePath=en.lproj#/remn37e1b56e)

## Why?

If you are a fan of David Allen's [GTD](http://gettingthingsdone.com/ "Getting Things Done"), you probably know how important it is to have only "One Inbox". Many people use something that syncs everywhere, such as Omnifocus or Things.

However for collaboration with others, many techies use [Atlassian JIRA] (https://www.atlassian.com/software/jira "Atlassian JIRA Product page"). This ends up in a weird "two inboxes" problems, that forces us to schedule our coding life separate from our non-coding life (both work and play).

This I believe leads to tremendous life imbalances. Do I code now, or do I write docs (which are not in JIRA)? On my "What's Next", are my coding tasks included?

JIRA To Task managers is a set of scripts that you can schedule on your Mac, which create one task for each of your assigned JIRA tasks. You can use cron to "set it and forget it", and get back to *One Inbox Bliss*.

If you're a coder, and you use a different (scriptable) task manager on your Mac, I invite you to code a destination (see below). JXA can be fun!

## Setting Up

This shows the setup for [Things](https://culturedcode.com/things/). They all work the same, just run the jira-to-(yourapp) instead.

Some projects may ask slightly different questions.

You may need to use [rvm](https://rvm.io/rvm/install) to install a newer ruby. I use 2.1.5, and it's what's specified in the Gemfile.

The first time you run it, it looks like this:

	(maybe RVM install or something..)
	$ bundle install
	(installs all your gems and goodies..)

	$ ./jira-to-things -C
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
	$ ./jira-to-things
	Running JQL:
	assignee = currentUser() order by priority desc
	Got 999 issues that we'll sync with your app

	Running add_to_things.jxa
	Finished updating 999 tasks in Things.

## Troubleshooting

### Can't get object on (JXA file)
``
jiratotaskmanagers/lib/task_destinations/add_to_omnifocus.jxa:1676:1700: execution error: Error on line 42: Error: Can't get object. (-1728)
``

This is nearly always a problem with your project or context not existing. Use the `--print-config` option to see the configuration and make sure your project names and contexts are correct. Go to the appropriate line (42 in this case) to see which variable is wrong for a hint.

Once you've determined what was wrong, `--clear-config` option to reconfigure, and answer the questions correctly.

### JIRA::HTTPError Unauthorized

``
/Users/David/.rvm/gems/ruby-2.1.5/gems/jira-ruby-0.1.14/lib/jira/request_client.rb:14:in `request': Unauthorized (JIRA::HTTPError)
``

This is a JIRA authentication error. We use JIRA basic auth. Clear your config and log in correctly.

Note that if you have never signed in to JIRA using a password (for example, if you use Google Apps login), you need to go to your profile, look at the username and click on "Set Password" to set an initial password. Make sure you can log in to JIRA directly.


## Adding it to Cron

You are set up! Now you can put it on a cron line, like this one which sets it to run at office
hours (use `crontab -e` in Terminal for this):

    */10 7-18 * * * /yourdir/jira-to-things > /yourdir/log/jira_to_omnifocus.log 2>&1

Congratulations!  You are done.

## Multiple Profiles

Say you have two or three filters you'd like to get imported with different settings (maybe subprojects, different contexts for different JIRAs, etc). For this you can use multiple profiles. Simply pass the `--config-file` option to set up a new yml file. For example:

  $ ./jira-to-things --config-file=myopensourceproject.yml
  Config: myopensourceproject.yml
  JIRA Url (usually https://yourdomain.atlassian.net):


### Security Warning

The password for your JIRA account will be saved on a file on your computer called
`~/.jiratoomnifocus/jira_credentials.yml`. It is encrypted using blowfish using a constant key.

As long as both your credentials file are secured as (chmod 700) and owned by the user that will be running it on cron), you should be okay and secure (unless someone breaks into your account, in which case you have bigger problems than your JIRA access!).

If this bothers you, you can set the environment variable `JIRA_TO_TASKS_CRYPT_KEY` to have the configuration store use a different key. You will need to run -C to clear the config that uses the old key.

## How to add New Destinations

So you have Super-Duper app and you want to add support for it? With JXA, this is now fairly simple to do. JXA is just like JavaScript, and you have our template here.

1. Copy `lib/task_destinations/add_to_things`.jxa and edit it.

	Start by changing TaskApp = Application("Things") to match the app you want to work with. Use Applescript Editor (or Textmate with [AppleScript JXA Bundle](https://github.com/hackerdude/AppleScript-JXA.tmbundle)) and a sample JSON file, or just finish the rest of the changes and do trial-and-error with your own app.
1. Copy `jira-to-things` to jira-to-(yourapp)
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
