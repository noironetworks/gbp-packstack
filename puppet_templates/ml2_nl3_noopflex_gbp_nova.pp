class { 'gbp::gbp_nova': 
  require => Class['gbp::ml2_nl3_noopflex::pkgs'],
}
