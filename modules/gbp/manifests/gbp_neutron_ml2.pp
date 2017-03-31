class gbp::gbp_neutron_ml2 (
  $enable_aim = hiera('CONFIG_ENABLE_AIM')
) {

   neutron_plugin_ml2 {
     'ml2/type_drivers': value => "opflex,local,flat,vlan,gre,vxlan";
     'ml2/tenant_network_types': value => "opflex";
     'ovs/local_ip': value => hiera('CONFIG_CONTROLLER_HOST');
   }

   if $enable_aim == "True" {
      neutron_plugin_ml2 {
         'ml2/mechanism_drivers': value => "apic_aim";
         'ml2/extension_drivers': value => "apic_aim,port_security";
      }
   } else {
      neutron_plugin_ml2 {
         'ml2/mechanism_drivers': value => "apic_gbp";
      }
   }

}
