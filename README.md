# gbp-packstack
This is a patch to packstack to support configuration of GBP, till it becomes part of packstack.

Installation
  These instructions are for RHEL7
  - Install packstack for Juno
  - Check out this repo
  - copy files under "puppet_templates" directory to /usr/lib/python2.7/site-packages/packstack/puppet/templates
  - copy files under "plugins" directory to /usr/lib/python2.7/site-packages/packstack/plugins
  - copy "gbp" directory under modules to /usr/share/openstack-puppet/modules directory
  - running packstack command will now accept GBP related parameters.
  
Notes:
  Currently the required packages are installed from Git repo. Once the packages are pushed upstream, the puppet modules will 
  change accordingly.
  
