class gbp::gbp_automation_ui() {

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

}
