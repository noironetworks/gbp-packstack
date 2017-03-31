class gbp::gbp_neutron_conf(
    $apic_controller = hiera('CONFIG_APIC_CONTROLLER'),
    $apic_username = hiera('CONFIG_APIC_USERNAME'),
    $apic_password = hiera('CONFIG_APIC_PW'),
    $apic_system_id = hiera('CONFIG_APIC_SYSTEM_ID'),
    $apic_provision_infra = hiera('CONFIG_APIC_PROVISION_INFRA'),
    $apic_provision_hostlinks = hiera('CONFIG_APIC_PROVISION_HOSTLINKS'),
    $apic_vpc_pairs = hiera('CONFIG_APIC_VPC_PAIRS'),
    $apic_domain_name = hiera('CONFIG_APIC_DOMAIN_NAME'),
    $enable_aim = hiera('CONFIG_ENABLE_AIM')
) {

   $k_auth_url = hiera('CONFIG_KEYSTONE_ADMIN_URL')

   neutron_config {
     'DEFAULT/default_log_levels': value => "neutron.context=ERROR";
     'DEFAULT/apic_system_id': value => $apic_system_id;
     'DEFAULT/state_path': value => '/var/lib/neutron';
     'DEFAULT/lock_path': value => '$state_path/lock';
     'opflex/networks': value => '*';
     'ml2_cisco_apic/root_helper': value => 'sudo neutron-rootwrap /etc/neutron/rootwrap.conf';
     'appliance_driver/svc_management_ptg_name': value => "Service-Management";
   }

   if $enable_aim == "True" {
     neutron_config {
       'DEFAULT/core_plugin':   value => 'ml2plus';
       'DEFAULT/service_plugins': value => 'group_policy,servicechain,apic_aim_l3';
       'apic_aim_auth/auth_plugin': value => 'v3password';
       'apic_aim_auth/auth_url':   value => "$k_auth_url/v3";
       'apic_aim_auth/username':   value => hiera('CONFIG_KEYSTONE_ADMIN_USERNAME');
       'apic_aim_auth/password':   value => hiera('CONFIG_KEYSTONE_ADMIN_PW');
       'apic_aim_auth/user_domain_name':  value => 'default';
       'apic_aim_auth/project_domain_name': value => 'default';
       'apic_aim_auth/project_name': value => 'admin';
       'group_policy/policy_drivers': value => 'aim_mapping';
       'group_policy/extension_drivers': value => 'aim_extension,proxy_group,apic_allowed_vm_name,apic_segmentation_label';
     }
   } else {
     neutron_config {
       'DEFAULT/core_plugin':   value => 'ml2';
       'DEFAULT/service_plugins': value => 'group_policy,servicechain,apic_gbp_l3';
       'ml2_cisco_apic/vni_ranges': value => '11000:11100';
       'ml2_cisco_apic/apic_hosts': value => $apic_controller;
       'ml2_cisco_apic/apic_username': value => $apic_username;
       'ml2_cisco_apic/apic_password': value => $apic_password;
       'ml2_cisco_apic/apic_domain_name': value => $apic_domain_name;
       'ml2_cisco_apic/use_vmm': value => True;
       'ml2_cisco_apic/apic_use_ssl': value => True;
       'ml2_cisco_apic/apic_clear_node_profiles': value => True;
       'ml2_cisco_apic/enable_aci_routing': value => True;
       'ml2_cisco_apic/enable_arp_flooding': value => True;
       'ml2_cisco_apic/apic_name_mapping': value => 'use_name';
       'ml2_cisco_apic/apic_entity_profile': value => 'openstack_noirolab';
       'ml2_cisco_apic/apic_vmm_domain': value => 'noirolab_vmm';
       'ml2_cisco_apic/apic_app_profile_name': value => 'noirolab_app';
       'ml2_cisco_apic/apic_provision_infra': value => $apic_provision_infra;
       'ml2_cisco_apic/apic_provision_hostlinks': value => $apic_provision_hostlinks;
       'ml2_cisco_apic/apic_vpc_pairs': value => $apic_vpc_pairs;
       'group_policy/policy_drivers': value => 'implicit_policy,apic';
       'group_policy_implicit_policy/default_ip_pool': value => '192.168.0.0/16';
     }
   }

   define add_switch_conn_to_neutron_conf($sa) {
       $sid = keys($sa)
       a_s_c_t_n_c_1{$sid: swarr => $sa}
   }
    
   define a_s_c_t_n_c_1($swarr) {
       $plist = $swarr[$name]
       $local_names = regsubst($plist, '$', "-$name")
       a_s_c_t_n_c_2 {$local_names: sid => $name}
   }
    
   define a_s_c_t_n_c_2($sid) {
       $orig_name = regsubst($name, '-[0-9]+$', '')
       $arr = split($orig_name, ':')
       $host = $arr[0]
       $swport = $arr[1]
       neutron_config {
          "apic_switch:$sid/$host": value => $swport;
       }
   }
    
   $use_lldp = hiera('CONFIG_GBP_USE_LLDP')
   $swarr = parsejson(hiera('CONFIG_APIC_CONN_JSON'))

   if ($use_lldp == "True") {
      #
   } else {
      if $enable_aim == "True" {
      } else {
         add_switch_conn_to_neutron_conf{'xyz': sa => $swarr}
      }
   }

   $extnet_arr = parsejson(hiera('CONFIG_APIC_EXTNET_JSON'))

   define add_extnet_to_neutron_conf($na) {
      $extnets = keys($na)
      add_extnet_def { $extnets: netarr => $na}
   }

   define add_extnet_def($netarr) {
     neutron_config {
        "apic_external_network:$name/switch": value => $netarr[$name]['switch'];
        "apic_external_network:$name/port": value => $netarr[$name]['port'];
        "apic_external_network:$name/encap": value => $netarr[$name]['encap'];
        "apic_external_network:$name/cidr_exposed": value => $netarr[$name]['cidr_exposed'];
        "apic_external_network:$name/gateway_ip": value => $netarr[$name]['gateway_ip'];
        "apic_external_network:$name/router_id": value => $netarr[$name]['router_id'];
     }
   }

   if $enable_aim == "True" {
   } else {
     add_extnet_to_neutron_conf{'abc': na => $extnet_arr}
   }
}
