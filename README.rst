Open Data Services Co-Op deployment git repository
==================================================

This repository is used to track files relating to deploying code etc. to  Open Data Services' servers.

Mostly it contains files designed for use with the salt deployment tool. http://saltstack.com/

Currently we use ``salt-ssh``, which eliminates the need to set up master/minion daemons. (The downside is that it does not scale so well, but this is unlikely to be a problem for us for the forseeable future.)

Using salt-ssh
--------------

Note: the instructions here assume a recent version of Salt. Although many linux distributions now package salt in the default repositories, the packages are likely to be out of date. It's recommended to install the most recent version of salt from http://docs.saltstack.com/en/latest/topics/installation/

.. code-block::

    salt-ssh --priv ~/.ssh/id_rsa <server name> <salt function>

Server names are defined in ``salt-config/roster``. If you want to define your own roster, you can use the ``--roster-file``  argument.

Salt functions are grouped into "execution modules". e.g. the ``state.sls`` function is in the ``state`` module. The full list of modules can be found at http://docs.saltstack.com/en/latest/ref/modules/all/, and a shorter list of particularly useful functions can be found below.

Running as a non-root user
--------------------------

By default salt-ssh assumes you want to run it as root. Running ``./setup_for_non_root.sh`` will make the necessary changes so that you don't have to.

Useful salt functions
---------------------

test.ping
    check that servers are there, and set up correctly.

    As with any salt command, we can use a glob to run this against all servers.

    .. code-block::

        salt-ssh '*' test.ping

state.highstate
    this deploys the states as defined in the top.sls file, e.g.

    .. code-block::

        salt-ssh <servername> state.highstate

state.sls
    this can be used to specify a single SLS formula file explicitly, e.g.

    .. code-block::

        salt-ssh <servername> state.sls <statename> [<environment name>]

pkg.upgrade
    to update the packages on the server. This is equivalent to sshing in and running apt-get/aptitude update/upgrade manually.

file.file_exists
    Check whether a file exists on the server. This is useful for seeing whether the server needs a reboot. e.g.

    .. code-block:: 

        salt-ssh '*' file.file_exists '/var/run/reboot-required'

system.reboot
    reboots the server.
