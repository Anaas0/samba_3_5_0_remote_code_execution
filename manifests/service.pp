#
class samba_3_5_0_remote_code_execution::service{
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
  # $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $user = 'samba'#$secgen_parameters['leaked_username'][0]

  file { '/etc/systemd/system/nmbd.service':
    source  => 'puppet:///modules/samba_3_5_0_remote_code_execution/nmbd.service',
    owner   => $user,
    mode    => '0777',
    require => File['/root/smbshare'],
    notify  => File['/etc/systemd/system/smbd.service'],
  }
  file { '/etc/systemd/system/smbd.service':
    source  => 'puppet:///modules/samba_3_5_0_remote_code_execution/smbd.service',
    owner   => $user,
    mode    => '0777',
    require => File['/etc/systemd/system/nmbd.service'],
    notify  => Service['nmbd'],
  }
  service { 'nmbd':
    ensure  => running,
    enable  => true,
    require => File['/etc/systemd/system/nmbd.service'],
    notify  => Service['smbd'],
  }
  service { 'smbd':
    ensure  => running,
    enable  => true,
    require => File['/etc/systemd/system/smbd.service'],
  }
}
