class gbp::ml2_nl3_noopflex::gbp_neutron_conf(
    $apic_system_id = hiera('CONFIG_APIC_SYSTEM_ID'),
) {

   neutron_config {
     'DEFAULT/default_log_levels': value => "neutron.context=ERROR";
     "DEFAULT/service_plugins": value => "router,group_policy,servicechain";
     "DEFAULT/apic_system_id": value => $apic_system_id;
     'group_policy/policy_drivers': value => 'implicit_policy,resource_mapping';
     'group_policy_implicit_policy/default_ip_pool': value => '192.168.0.0/16';
     'appliance_driver/svc_management_ptg_name': value => "Service-Management";
   }

}
