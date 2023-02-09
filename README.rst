Open Data Services Co-Operative deployment git repository
=========================================================

This repository is used to track files relating to deploying code etc. to Open Data Services Co-operative's servers. More general information about our development and deployment approach can be found in our developer docs at https://github.com/OpenDataServices/developer-docs

Mostly it contains files designed for use with the salt deployment tool. http://saltstack.com/

Currently we use ``salt-ssh``, which eliminates the need to set up master/minion daemons. (The downside is that it does not scale so well, but this is unlikely to be a problem for us for the foreseeable future.)

This repository is public, but some salt states rely on private information e.g. passwords to be set up in the `pillar/private` directory. Internally we have instructions for setting up our own private information at https://opendataservices.plan.io/projects/co-op/wiki/Servers#Getting-Started.

Using salt-ssh
--------------

Make sure you run the version of salt that is specified in the requirements.in file. You can make a python virtual environment and install requirements.txt, or use another method.

This repository contains a `Saltfile` which ensures that salt-ssh files from this directory will pick up the config in `salt-config`. Any extra configuration you want to do should be done in this directory, and not `/etc/salt`. Also, to make use of this, all salt commands must be run from the root directory of this repository.

You will need to add your SSH key to `salt-config/pki/ssh`. The script `setup_for_non_root.sh` contains an example of this.

.. code-block::

    salt-ssh <server name> <salt function>

Server names are defined in ``salt-config/roster``. If you want to define your own roster, you can use the ``--roster-file``  argument. You can also use globs as a server name, e.g. `'*'` (needs quoting to avoid being interpreted as a shell glob), and `-L` to supply a commma separated list of server names, e.g.

.. code-block::

    salt-ssh -L server1,server2 <server name> <salt function>

If this is the very first time you are connecting to a server on a new IP address, you can specify ``-i`` to avoid warnings from ssh, e.g.

.. code-block::

    salt-ssh -i <server name> <salt function>

Salt functions are grouped into "execution modules". e.g. the ``state.sls`` function is in the ``state`` module. The full list of modules can be found at http://docs.saltstack.com/en/latest/ref/modules/all/, and a shorter list of particularly useful functions can be found below.

Running as a non-root user
--------------------------

By default salt-ssh assumes you want to run it as root. Running ``./setup_for_non_root.sh`` will make the necessary changes so that you don't have to.

Useful salt functions
---------------------

test.ping
    check that servers are there, and set up correctly.

    .. code-block::

        salt-ssh '*' test.ping

state.highstate
    this deploys the states as defined in the top.sls file, e.g.

    .. code-block::

        salt-ssh <servername> state.highstate

    to better control the amount of output, specify ``--state-output=mixed`` , e.g.

    .. code-block::

        salt-ssh <servername> --state-output=mixed state.highstate

state.sls
    this can be used to specify a single SLS formula file explicitly, e.g.

    .. code-block::

        salt-ssh <servername> state.sls <statename>

pkg.list_upgrades
    list what packages can be upgraded on the servers. Use refresh=True to ensure the package list is refreshed (ie. apt-get update), e.g.

    .. code-block::

        salt-ssh '*' pkg.list_upgrades refresh=True

pkg.upgrade
    to update the packages on the server. This is equivalent to sshing in and running apt-get/aptitude update/upgrade manually.

file.file_exists
    Check whether a file exists on the server. This is useful for seeing whether the server needs a reboot. e.g.

    .. code-block:: 

        salt-ssh '*' file.file_exists '/var/run/reboot-required'

system.reboot
    reboots the server.
