# this is all temporary.. till the packages are available

class gbp(
) {

   if !defined(Package['python-pip']) {
      package { 'python-pip':
         ensure => installed,
         provider => yum,
      }
   }

   if !defined(Package['python-pbr']) {
      package { 'python-pbr':
         ensure => installed,
      }
   }

   if !defined(Package['neutron-opflex-agent']) {
      package {'neutron-opflex-agent':
         ensure => installed,
         provider => yum,
      }
   }

   if !defined(Package['apicapi']) {
      package {'apicapi':
         ensure => installed,
         provider => yum,
      }
   }
   
   if !defined(Package['openstack-neutron-gbp']) {
      package {'openstack-neutron-gbp':
         ensure => installed,
         provider => yum,
      }
   }

   if !defined(Package['python-gbpclient']) {
      package {'python-gbpclient':
         ensure => installed,
         provider => yum,
      }
   }

   if !defined(Package['neutron-ml2-driver-apic']) {
      package {'neutron-ml2-driver-apic':
         ensure => installed,
         provider => yum,
      }
   }
}
