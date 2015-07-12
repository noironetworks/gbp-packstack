class gbp::ml2_nl3_noopflex::gbp_ml2_conf_cisco() {

   neutron_plugin_ml2_cisco {
     'ml2_cisco_apic/apic_hosts': value => hiera('CONFIG_APIC_CONTROLLER');
     'ml2_cisco_apic/apic_username': value => hiera('CONFIG_APIC_USERNAME');
     'ml2_cisco_apic/apic_password': value => hiera('CONFIG_APIC_PW');
     'ml2_cisco_apic/apic_use_ssl': value => True;
     'ml2_cisco_apic/use_vmm': value => True;
     'ml2_cisco_apic/apic_clear_node_profiles': value => True;
     'ml2_cisco_apic/apic_app_profile_name': value => "noiro";
     'ml2_cisco_apic/apic_model': value => "neutron.plugins.ml2.drivers.cisco.apic.apic_model";
     'ml2_cisco_apic/apic_name_mapping': value => "use_name";
     'ml2_cisco_apic/root_helper': value => 'sudo';
     'ml2_cisco_apic/enable_aci_routing': value => False;
     'ml2_cisco_apic/enable_arp_flooding': value => True;
   }
     #'ml2_cisco_apic/scope_names': value => False;

   $swarr = parsejson(hiera('CONFIG_APIC_CONN_JSON'))

   define add_switch_conn_to_neutron_ml2_cisco_conf($sa) {
      $sid = keys($sa)
      a_s_c_t_n_c_1{$sid: swarr => $sa}
   }

   define a_s_c_t_n_c_1($swarr) {
      $plist = $swarr[$name]
      a_s_c_t_n_c_2 {$plist: sid => $name}
   }

   define a_s_c_t_n_c_2($sid) {
      $arr = split($name, ':')
      $host = $arr[0]
      $swport = $arr[1]
      neutron_plugin_ml2_cisco {
        "apic_switch:$sid/$host": value => $swport;
      }
   }

   add_switch_conn_to_neutron_ml2_cisco_conf{'xyz': sa => $swarr}

   $extnet_arr = parsejson(hiera('CONFIG_APIC_EXTNET_JSON'))

   define add_extnet_to_neutron_ml2_cisco_conf($na) {
      $extnets = keys($na)
      add_extnet_def { $extnets: netarr => $na}
   }

   define add_extnet_def($netarr) {
     neutron_plugin_ml2_cisco {
        "apic_external_network:$name/switch": value => $netarr[$name]['switch'];
        "apic_external_network:$name/port": value => $netarr[$name]['port'];
        "apic_external_network:$name/encap": value => $netarr[$name]['encap'];
        "apic_external_network:$name/cidr_exposed": value => $netarr[$name]['cidr_exposed'];
        "apic_external_network:$name/gateway_ip": value => $netarr[$name]['gateway_ip'];
        "apic_external_network:$name/router_id": value => $netarr[$name]['router_id'];
     }
   }

   add_extnet_to_neutron_ml2_cisco_conf{'abc': na => $extnet_arr}
}
