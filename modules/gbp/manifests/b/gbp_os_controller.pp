class gbp::gbp_os_controller() {

   $srcdir = "/root/sources1"
   $gbp_automation_dir = "${srcdir}/gbpautomation"
   $gbp_ui_dir = "${srcdir}/gbpuidir"

  file { "remove_src1_dir":
     name => $srcdir,
     ensure => absent,
     force => true,
     purge => true,
     recurse => true,
  }
  exec { "create_src1_dir":
     command => "/bin/mkdir $srcdir",
     require => File['remove_src1_dir'],
  }

   class {'gbp::gbp_neutron_conf':
      notify => Service['neutron-server'],
   }
  
   neutron_plugin_ml2 {
     'ml2/type_drivers': value => "opflex,local,flat,vlan,gre,vxlan";
     'ml2/tenant_network_types': value => "opflex";
     'ml2/mechanism_drivers': value => "apic_gbp";
     'ovs/local_ip': value => hiera('CONFIG_CONTROLLER_HOST');
   }

   exec {'gbp_db':
      command => "/usr/bin/gbp-db-manage --config-file /etc/neutron/neutron.conf upgrade head",
      require => [ Neutron_config['DEFAULT/apic_system_id'], Neutron_plugin_ml2['ovs/local_ip'] ],
      notify => Service['neutron-server'],
   }

   if !defined(Service['neutron-server']) {
      service {'neutron-server':
         ensure => running,
         enable => true,
      }
   }

   exec {'get_gbp_automation':
      command => "/usr/bin/git clone https://github.com/noironetworks/group-based-policy-automation.git -b noiro $gbp_automation_dir",
      creates => $gbp_automation_dir,
      require => Exec['create_src1_dir'],
   }

   Heat_config<||> ~> Service['openstack-heat-api','openstack-heat-engine']

   exec {'install_gbp_automation':
      command => "/usr/bin/python setup.py install",
      cwd => $gbp_automation_dir,
      require => Exec['get_gbp_automation'],
   } ->
   heat_config {
      'DEFAULT/plugin_dirs': value => "/usr/lib/python2.7/site-packages/gbpautomation/heat";
   } ->
   file {'/etc/heat/api-paste.ini':
     content => template('gbp/heat-api-paste.ini.erb'),
   } 

   service {'openstack-heat-engine':
     ensure => 'running',
     enable => true,
   } 
   service {'openstack-heat-api':
     ensure => 'running',
     enable => true,
   }

#   file { $gbp_automation_dir:
#     ensure => absent,
#     force => true,
#     purge => true,
#     recurse => true,
#     require => Exec['install_gbp_automation'],
#   }   

   exec {'get_gbp_ui':
      command => "/usr/bin/git clone https://github.com/noironetworks/group-based-policy-ui.git -b noiro $gbp_ui_dir",
      creates => $gbp_ui_dir,
      require => Exec['create_src1_dir'],
   }
   exec {'install_gbp_ui':
      command => "/usr/bin/python setup.py install",
      cwd => $gbp_ui_dir,
      require => Exec['get_gbp_ui'],
   } 

   exec {'link-enabled':
     command => "/usr/bin/ln -sf /usr/lib/python2.7/site-packages/gbpui/_*project*.py /usr/share/openstack-dashboard/openstack_dashboard/enabled/",
     require => Exec['install_gbp_ui'],
   } ->
   service {'httpd':
      ensure => 'running',
      enable => true,
   }

#   file { $gbp_ui_dir:
#     ensure => absent,
#     force => true,
#     purge => true,
#     recurse => true,
#     require => Exec['install_gbp_ui'],
#   }   

   ##nova config
   Nova_config<||> ~> Service['openstack-nova-api']

   nova_config {
     'neutron/allow_duplicate_networks': value => "true";
   } 

   service {'openstack-nova-api':
      ensure => running,
      enable => true,
   }

}
