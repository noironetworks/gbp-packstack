class gbp::ml2_nl3_noopflex::gbp_ml2_conf() {

   neutron_plugin_ml2 {
     'ml2/type_drivers': value => "local,flat,vlan,gre,vxlan";
     'ml2/mechanism_drivers': value => "openvswitch, cisco_apic_ml2";
     'ovs/local_ip': value => hiera('CONFIG_CONTROLLER_HOST');
   }

}
