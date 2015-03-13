class { 'gbp::gbp_neutron_nova_api': 
   require => Class['gbp::gbp_neutron_conf', 'gbp::gbp_neutron_ml2'],
}
