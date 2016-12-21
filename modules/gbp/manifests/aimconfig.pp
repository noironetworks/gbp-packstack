class gbp::aimconfig(
) {

  $apic_controller   = hiera('CONFIG_APIC_CONTROLLER')
  $apic_username     = hiera('CONFIG_APIC_USERNAME')
  $apic_password     = hiera('CONFIG_APIC_PW')
  $apic_system_id    = hiera('CONFIG_APIC_SYSTEM_ID')

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
     'DEFAULT/apic_system_id':                    value => $apic_system_id;
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
     'apic/scope_names':                          value => False;
     'apic_vmdom:ostack/#dummy':                        value => '';
  }  

}
