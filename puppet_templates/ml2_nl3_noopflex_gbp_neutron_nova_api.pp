class { 'gbp::ml2_nl3_noopflex::gbp_neutron_nova_api': 
   require => Class['gbp::ml2_nl3_noopflex::gbp_neutron_conf', 'gbp::ml2_nl3_noopflex::gbp_ml2_conf', 'gbp::ml2_nl3_noopflex::gbp_ml2_conf_cisco'],
}

