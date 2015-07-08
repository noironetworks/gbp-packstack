class gbp::gbp_neutron_ml2 () {

   neutron_plugin_ml2 {
     'ml2/type_drivers': value => "opflex,local,flat,vlan,gre,vxlan";
     'ml2/tenant_network_types': value => "opflex";
     'ml2/mechanism_drivers': value => "apic_gbp";
     'ovs/local_ip': value => hiera('CONFIG_CONTROLLER_HOST');
   }

}
