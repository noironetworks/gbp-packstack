class gbp::aimservice(
) {

  exec {'aim-db-migrate':
    command => "/usr/bin/aimctl db-migration upgrade head",
  }

  exec {'aim-config-update':
    command => "/usr/bin/aimctl config update",
    require => Exec['aim-db-migrate'],
  }
 
  exec {'aim-create-infra':
    command => "/usr/bin/aimctl infra create",
    require => Exec['aim-config-update'],
  }

  exec {'aim-load-domains':
    command => "/usr/bin/aimctl manager load-domains --enforce",
    require => Exec['aim-config-update'],
  }

  service {'aim-aid':
      ensure => running,
      enable => true,
      require => Exec['aim-load-domains'],
  }

  service {'aim-event-service-polling':
      ensure => running,
      enable => true,
      require => Exec['aim-load-domains'],
  }

  service {'aim-event-service-rpc':
      ensure => running,
      enable => true,
      require => Exec['aim-load-domains'],
  }
}
