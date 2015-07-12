class { 'gbp::gbp_automation_ui': 
  require => Class['gbp::ml2_nl3_noopflex::pkgs'],
}
