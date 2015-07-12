class gbp::ml2_nl3_noopflex::gbp_neutron_dhcp() {

   Neutron_dhcp_agent_config<||> ~> Service['neutron-dhcp-agent']

   neutron_dhcp_agent_config {
      'DEFAULT/ovs_integration_bridge': value => "br-int";
      'DEFAULT/enable_isolated_metadata': value => False;
   } ->

   service {'neutron-dhcp-agent':
      ensure => running,
      enable => true,
   }
}
