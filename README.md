asterisk-configs
================

Configurations I use for testing Asterisk. Currently, the configuration supports Asterisk 13.

Since I use Linux Mint, the install script has been set up for that distribution. If you are using something else, you will need to modify the install script accordingly (in particular, the system library installation).

**NOTE: THE ACCOUNTS USED HEREIN ARE EXTREMELY INSECURE. DO NOT USE.**

### Install Script

This script can:
* Install system libraries needed for Asterisk and PJPROJECT
* Download, configure, and install Asterisk and PJPROJECT
* Install a set of configuration files that are useful for testing/hacking

You should invoke this script such that it can install Asterisk and PJPROJECT. This generally, means installing using sudo; however, your mileage may vary. By default, this script will only install the Asterisk configuration files.

Note that if you install Asterisk using some other mechanism, you may not be able to install the configuration files using this script.

* -u: User that will own Asterisk and its configuration files
* -g: Group for the user that will own Asterisk and its configuration files
* -i: Pull down Asterisk/PJPROJECT and install it
* -w: Wipe the existing configuration before installing the new configuration files

Currently, you have to modify the install script if you'd like to install a different version of Asterisk.

### Asterisk Configuration

Most of the configuration is 'blank', in that it disables most services that aren't necessary and provides only a few basic items. These include:
* Two PJSIP endpoints, Alice and Bob
* Some basic dialplan to dial the endpoints and a Stasis application
* A single ARI user

These are described in more detail below.

#### Modules

Modules are explicitly loaded. Most modules non-essential modules are not loaded, as the configuration focuses on PJSIP and ARI. If additional modules are needed, you'll need to manually load them or update the modules.conf.

Note that not all PJSIP modules are loaded, in particular, res_pjsip_t38, because fax should die.

#### PJSIP Configuration

Two endpoints are defined, Alice and Bob. Both are assumed to register to Asterisk with a single contact. The settings for Alice and Bob are set up 'defensively', in that many of the settings that assist with NAT are enabled. Your mileage may vary, depending on where your phones are located.

If you do have a NAT, make sure you uncomment the localnet settings in the [transport] sections.

#### Dialplan

While some handy subroutines have been set up to do the basic dialling, the following is a cheat sheet:

* 1000: Dial Alice
* 2000: Dial Bob
* 10000: Place the channel into Stasis

Modify the STASIS_APP and STASIS_ARGS global variables for the Stasis application at extension 10000.

#### ARI Configuration

A single ARI user has been configured with username/password of asterisk/asterisk.

### ARI Applications

The following applications are in the ari-apps folder:

* conference.py: Registers as the 'conference' ARI application. Acts as a very, very basic conferencing application.

