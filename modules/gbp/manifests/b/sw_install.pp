#temporary class to install packages from git till the repo comes online.
class gbp::sw_install() {

  $srcdir = "/root/sources"
  $gbpdir = "/${srcdir}/gbpovsagent"
  $apicapidir = "/${srcdir}/apicapi"
  $pyopflexagent = "/${srcdir}/pyopflexagent"
  $python_gbpclient_dir = "/${srcdir}/gbpclient"
 
  if !defined(Package['git']) {
     package {'git':
        ensure => installed,
     }
  }
  package {'wireshark':
    ensure => installed,
  }
  package {'wireshark-gnome':
    ensure => installed,
  }
  package {'emacs':
    ensure => installed,
  }

  file { "remove_src_dir":
     name => $srcdir,
     ensure => absent,
     force => true,
     purge => true,
     recurse => true,
  }
  exec { "create_src_dir":
     command => "/bin/mkdir $srcdir",
     require => File['remove_src_dir'],
  }

  exec { 'get_gbp_ovs_agent':
     command => "/usr/bin/git clone https://github.com/noironetworks/group-based-policy.git -b noiro $gbpdir",
     creates => $gbpdir,
     require => Exec['create_src_dir'],
  }

  exec {'get_apicapi':
     command => "/usr/bin/git clone https://github.com/noironetworks/apicapi.git -b noiro $apicapidir",
     creates => $apicapidir,
     require => Exec['create_src_dir'],
  }

  exec {'get_python_opflex_agent':
     command => "/usr/bin/git clone https://github.com/noironetworks/python-opflex-agent.git -b master $pyopflexagent", 
     creates => $pyopflexagent,
     require => Exec['create_src_dir'],
  }
 
  exec {'get_py_gbp_client':
     command => "/usr/bin/git clone https://github.com/noironetworks/python-group-based-policy-client.git -b noiro $python_gbpclient_dir", 
     creates => $python_gbpclient_dir,
     require => Exec['create_src_dir'],
  }
 
 
  exec {'install_gbp_ovs_agent':
     command => "/usr/bin/python setup.py install",
     cwd => $gbpdir,
     require => Exec['get_gbp_ovs_agent'],
  }

  exec {'install_apicapi':
     command => "/usr/bin/python setup.py install",
     cwd => $apicapidir,
     require => Exec['get_apicapi'],
  }

  exec {'install_pyopflexagent':
     command => "/usr/bin/python setup.py install",
     cwd => $pyopflexagent,
     require => Exec['get_python_opflex_agent'],
  }

  exec {'install_py_gbp_client':
     command => "/usr/bin/python setup.py install",
     cwd => $python_gbpclient_dir,
     require => Exec['get_py_gbp_client'],
  }

#  file {$gbpdir:
#     ensure => absent,
#     force => true,
#     purge => true,
#     recurse => true,
#     require => Exec['install_gbp_ovs_agent'],
#  }
#  
#  file {$apicapidir:
#     ensure => absent,
#     force => true,
#     purge => true,
#     recurse => true,
#     require => Exec['install_apicapi'],
#  }
#
#  file {$pyopflexagent:
#     ensure => absent,
#     force => true,
#     purge => true,
#     recurse => true,
#     require => Exec['install_pyopflexagent'],
#  }
#
#  file { $python_gbpclient_dir:
#     ensure => absent,
#     force => true,
#     purge => true,
#     recurse => true,
#     require => Exec['install_py_gbp_client'],
#  }

    
}
