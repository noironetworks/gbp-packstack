class gbp::aim(
    $enable_aim = hiera('CONFIG_ENABLE_AIM')
) {
   if $enable_aim == "True" {
      package {'aci-integration-module':
         ensure => installed,
         provider => yum,
      }
      class { 'gbp::aimconfig':
         require => Package['aci-integration-module'],
      }
      class { 'gbp::aimservice':
         require => Class['gbp::aimconfig'],
      }
   }
}
