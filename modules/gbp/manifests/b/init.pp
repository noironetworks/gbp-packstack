class gbp() {

   if !defined(Package['python-pip']) {
      package { 'python-pip':
         ensure => installed,
         provider => yum,
      }
   }

   if !defined(Package['python-pbr.noarch']) {
      package { 'python-pbr.noarch':
         ensure => installed,
      }
   }

}
