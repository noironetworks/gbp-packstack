class { 'gbp::ml2_nl3_noopflex::gbp_neutron_conf': 
   require => Class['gbp::ml2_nl3_noopflex::pkgs'],
}
