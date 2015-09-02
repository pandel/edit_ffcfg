General
=======

Edit_ffcfg is a command line tool for manipulating Firefox auto-configuration files.


INI format description:
=======================
::

	[general]
	ff_cfg = <path to firefox auto-configuration file>

	[single_parameter]
	count = <number of parameter entries that follow>
	param1 = <first parameter to be added, deleted or changed>
	param2 = <second parameter to be added, deleted or changed>
	....

	[capability_policies]
	count = <number of policy entries that follow>
	policy1 = <first policy to be added, deleted or changed>
	policy2 = <second policy to be added, deleted or changed>

I) Single_parameter entry format:
=================================

A parameter has to be written in the following format::

	<preference type>|<parameter name>|<parameter value>

- <preference type> is one of values: pref, lockPref, defaultPref, user_pref
- <parameter name> is the exact name, ie. "auto.update.enabled", "social.active", ... BUT WITHOUT QUOTES!!!!!
- <parameter value> value of parameter, only use quotes is these are part of the value

All values have to be separated by a single | symbol.

a) Adding/Editing parameters:
-----------------------------

Example::

	param1=pref|pref.advanced.javascript.disable_button.advanced|false
	param2=lockPref|plugins.hide_infobar_for_outdated_plugin|True

Resulting configuration lines::

	pref("pref.advanced.javascript.disable_button.advanced", false);
	lockPref("plugins.hide_infobar_for_outdated_plugin", false);

b) Removing a parameter:
------------------------

If you specify only the first two values and end the second parameter with a | symbol,
the parameter will be removed from the file.
::

	param<n>=<preference type>|<parameter name>|

Example::

	param1=pref|auto.update.enable|

would remove the line::

	pref("auto.update.enable", ...);

completely.


II) Capability_policies entry format:
=====================================

A policy has to be written in the following format::

	<preference type>|<policy name>|<sites value>[|<policy.parameter name>|<policy.parameter value>][|<policy.parameter name>|<policy.parameter value>]....

Mandatory values:

- <preference type> is one of values: pref, lockPref, defaultPref, user_pref
- <policy name> policy name, ie. "my_policy", BUT WITHOUT QUOTES
- <sites value> site to apply this policy to, ie. "http://my.server.local", "http://my.server.local:4646", BUT WITHOUT QUOTES

Optional values (multiple parameter<->value pairs possible):

- <policy.parameter name> parameter name for this policy
- <policy.parameter value> parameter value for this policy

All values have to be separated by a single | symbol.

a) Adding/Editing policies:
---------------------------

Example::

	policy1=pref|our_links|"http://server.local.net"|checkloaduri.enabled|"allAccess"
	policy2=pref|more_of_our_links|"http://server2.local.net:4646"|checkloaduri.enabled|"allAccess"|Clipboard.cutcopy|"allAccess"|Clipboard.paste|"allAccess"

Resulting configuration lines::

	pref("capability.policy.policynames", "our_links,more_of_our_links");
	pref("capability.policy.our_links.sites", "http://server.local.net");
	pref("capability.policy.our_links.checkloaduri.enabled", "allAccess");
	pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");
	pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");
	pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");
	pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");

b) Removing policies:
---------------------

If you specify only the first two values and end the second parameter with a | symbol,
the policy will be completely removed from the file.
::

	<preference type>|<policy name>|

Let's take the last example result as an existing configuration. A policy line like
::

	policy1=pref|our_links|

would result in the following change::

	pref("capability.policy.policynames", "more_of_our_links");
	pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");
	pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");
	pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");
	pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");

III) Already existing parameters / policies not mentioned in the INI file:
==========================================================================

Already existing parameters or policies, which are not mentioned in the INI file, will be simply retained.
It is obvious for normal single-line parameters. To show a more detailed example for policies,
let's assume you already had the following policy lines in your auto-configuration file::

	pref("capability.policy.policynames", "alreadytheir,more_of_our_links");
	pref("capability.policy.alreadytheir", "http://server.local.net");
	pref("capability.policy.alreadytheir", "allAccess");
	pref("capability.policy.more_of_our_links.sites", "http://server2.local.net:4646");
	pref("capability.policy.more_of_our_links.checkloaduri.enabled", "allAccess");
	pref("capability.policy.more_of_our_links.Clipboard.cutcopy", "allAccess");
	pref("capability.policy.more_of_our_links.Clipboard.paste", "allAccess");

If you now apply the following rules::

	policy1=pref|our_links|"http://server.local.net"|checkloaduri.enabled|"allAccess"
	policy2=pref|more_of_our_links|

the result would be::

	pref("capability.policy.policynames", "alreadytheir,our_links");
	pref("capability.policy.alreadytheir", "http://server.local.net");
	pref("capability.policy.alreadytheir", "allAccess");
	pref("capability.policy.our_links.sites", "http://server.local.net");
	pref("capability.policy.our_links.checkloaduri.enabled", "allAccess");
