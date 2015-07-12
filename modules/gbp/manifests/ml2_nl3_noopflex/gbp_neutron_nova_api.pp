class gbp::ml2_nl3_noopflex::gbp_neutron_nova_api() {
   exec {'gbp_db':
      command => "/usr/bin/gbp-db-manage --config-file /etc/neutron/neutron.conf upgrade head",
      notify => Service['neutron-server'],
   }

   file_line {'modify neutron-server service':
      path => '/usr/lib/systemd/system/neutron-server.service',
      line => 'ExecStart=/usr/bin/neutron-server --config-file /usr/share/neutron/neutron-dist.conf --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugin.ini --config-file /etc/neutron/plugins/ml2/ml2_conf_cisco.ini --log-file /var/log/neutron/server.log',
      match => "ExecStart.*$",
   } ->
   exec {'daemon-reload':
      command => "/usr/bin/systemctl daemon-reload",
      notify => Service['neutron-server']
   }

   if !defined(Service['neutron-server']) {
      service {'neutron-server':
         ensure => running,
         enable => true,
      }
   }

   Nova_config<||> ~> Service['openstack-nova-api']

   nova_config {
     'neutron/allow_duplicate_networks': value => "true";
     'DEFAULT/vendordata_driver': value => "nova.api.metadata_vendordata_json.JsonFileVendorData";
   }

   service {'openstack-nova-api':
      ensure => running,
      enable => true,
   }
}
