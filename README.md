# gbp-packstack
This is a patch to packstack to support configuration of GBP, till it becomes part of packstack.

Installation
  These instructions are for RHEL7
  - Install packstack for Juno
  - Check out this repo
  - copy files under "puppet_templates" directory to /usr/lib/python2.7/site-packages/packstack/puppet/templates
  - copy files under "plugins" directory to /usr/lib/python2.7/site-packages/packstack/plugins
  - copy "gbp" directory under modules to /usr/share/openstack-puppet/modules directory
  - For Kilo release
    -   copy kilo_plugins/prescript_000.py.kilo to /usr/lib/python2.7/site-packages/packstack/plugins/prescript_000.py
    -   copy kilo_plugins/puppet_950.py.kilo	 to /usr/lib/python2.7/site-packages/packstack/plugins/puppet_950.py
  - running packstack command will now accept GBP related parameters.
  
Notes:
  Currently the required packages are installed from Git repo. Once the packages are pushed upstream, the puppet modules will 
  change accordingly.
  
