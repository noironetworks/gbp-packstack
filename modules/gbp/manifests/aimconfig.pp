class gbp::aimconfig(
) {

  $apic_controller          = hiera('CONFIG_APIC_CONTROLLER')
  $apic_username            = hiera('CONFIG_APIC_USERNAME')
  $apic_password            = hiera('CONFIG_APIC_PW')
  $apic_system_id           = hiera('CONFIG_APIC_SYSTEM_ID')
  $apic_provision_infra     = hiera('CONFIG_APIC_PROVISION_INFRA')
  $apic_provision_hostlinks = hiera('CONFIG_APIC_PROVISION_HOSTLINKS')
  $apic_vpc_pairs           = hiera('CONFIG_APIC_VPC_PAIRS')
  $apic_domain_name         = hiera('CONFIG_APIC_DOMAIN_NAME')

  $neutron_db_host         = hiera('CONFIG_MARIADB_HOST_URL')
  $neutron_db_name         = hiera('CONFIG_NEUTRON_L2_DBNAME')
  $neutron_db_user         = 'neutron'
  $neutron_db_password     = hiera('CONFIG_NEUTRON_DB_PW')
  $neutron_sql_connection  = "mysql+pymysql://${neutron_db_user}:${neutron_db_password}@${neutron_db_host}/${neutron_db_name}"
  $rabbit_host           = hiera('CONFIG_AMQP_HOST_URL')
  $rabbit_port           = hiera('CONFIG_AMQP_CLIENTS_PORT')
  $rabbit_user           = hiera('CONFIG_AMQP_AUTH_USER')
  $rabbit_password       = hiera('CONFIG_AMQP_AUTH_PASSWORD')

  aim_config {
     'DEFAULT/debug':                             value => True;
     'database/connection':                       value => $neutron_sql_connection;
     'oslo_messaging_rabbit/rabbit_host':         value => $rabbit_host;
     'oslo_messaging_rabbit/rabbit_port':         value => $rabbit_port;
     'oslo_messaging_rabbit/rabbit_hosts':        value => "$rabbit_host:$rabbit_port";
     'oslo_messaging_rabbit/rabbit_userid':       value => $rabbit_user;
     'oslo_messaging_rabbit/rabbit_password':     value => $rabbit_password;
     'apic/apic_hosts':                           value => $apic_controller;
     'apic/apic_username':                        value => $apic_username;
     'apic/apic_password':                        value => $apic_password;
     'apic/apic_use_ssl':                         value => True;
     'apic/verify_ssl_certificate':               value => False;
  }  

  aimctl_config {
     'DEFAULT/apic_system_id':                    value => $apic_system_id;
     'apic_vmdom:ostack/encap_mode':              value => 'vxlan';
     'apic/apic_domain_name':                     value => $apic_domain_name; 
     'apic/apic_entity_profile':                  value => 'openstack_noirolab';
     'apic/apic_vmm_domain':                      value => 'noirolab_vmm';
     'apic/apic_app_profile_name':                value => 'noirolab_app';
     'apic/apic_provision_infra':                 value => $apic_provision_infra;
     'apic/apic_provision_hostlinks':             value => $apic_provision_hostlinks;
     'apic/apic_vpc_pairs':                       value => $apic_vpc_pairs;
  }

   define add_switch_conn_to_aimctl_conf($sa) {
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
       aimctl_config {
          "apic_switch:$sid/$host": value => $swport;
       }
   }

   $use_lldp = hiera('CONFIG_GBP_USE_LLDP')
   $swarr = parsejson(hiera('CONFIG_APIC_CONN_JSON'))

   if ($use_lldp == "True") {
   } else {
       add_switch_conn_to_aimctl_conf{'xyz': sa => $swarr}
   }

   $extnet_arr = parsejson(hiera('CONFIG_APIC_EXTNET_JSON'))

   define add_extnet_to_aimctl_conf($na) {
      $extnets = keys($na)
      add_extnet_def { $extnets: netarr => $na}
   }
   define add_extnet_def($netarr) {
     aimctl_config {
        "apic_external_network:$name/switch": value => $netarr[$name]['switch'];
        "apic_external_network:$name/port": value => $netarr[$name]['port'];
        "apic_external_network:$name/encap": value => $netarr[$name]['encap'];
        "apic_external_network:$name/cidr_exposed": value => $netarr[$name]['cidr_exposed'];
        "apic_external_network:$name/gateway_ip": value => $netarr[$name]['gateway_ip'];
        "apic_external_network:$name/router_id": value => $netarr[$name]['router_id'];
     }
   }

   add_extnet_to_aimctl_conf{'abc': na => $extnet_arr}
}
