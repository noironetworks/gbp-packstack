class { 'gbp::gbp_neutron_dhcp': 
  require => Class['gbp'],
}
