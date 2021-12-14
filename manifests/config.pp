#
class samba_3_5_0_remote_code_execution::config{
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ], environment => [ 'http_proxy=172.22.0.51:3128', 'https_proxy=172.22.0.51:3128' ] }
  # SecGen Parameters
  # $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $user = 'samba'#$secgen_parameters['leaked_username'][0]
  $user_home = "/home/${user}"
  $build_dir = '/opt/samba_3_5_0'
  $config_file_dir = '/usr/local/samba/lib'
  $test_dir = '/usr/local/samba/bin'
  $binary_dir = '/usr/local/samba/sbin'

  # Create user(s)
  user { "${user}":
    ensure     => present,
    uid        => '666',
    gid        => 'root',#
    home       => "${user_home}/",
    managehome => true,
    require    => File["${build_dir}/"],
    notify     => File["${build_dir}samba_3_5_0.tar.gz"],
  }

  # Create user shares
  file { "/home/${user}/Public":
    ensure  => 'directory',
    owner   => $user,
    mode    => '0777',
    require => User["${user}"],
    notify  => File["/home/${user}/Bob"],
  }

  file { "/home/${user}/Bob":
    ensure  => 'directory',
    owner   => $user,
    mode    => '0777',
    require => File["/home/${user}/Public"],
    notify  => File["/home/${user}/John"],
  }

  file { "/home/${user}/John":
    ensure  => 'directory',
    owner   => $user,
    mode    => '0777',
    require => File["/home/${user}/Bob"],
    notify  => File['/root/smbshare'],
  }
  file { '/root/smbshare':
    ensure  => 'directory',
    owner   => $user,
    mode    => '0777',
    require => File["/home/${user}/John"],
    notify  => Exec['start-nmbd'],
  }

  # Set perms

  # Test the smb.conf
#  exec { 'test-conf':
#    cwd     => "${test_dir}",
#    command => 'sudo ./testparm',
#    require => File["/home/${user}/John"],
#    notify  => Exec[''],
#  }

  # Start nmbd -D & smbd -D
  exec { 'start-nmbd':
    cwd     => "${binary_dir}/",
    command => 'sudo ./nmbd -D',
    require => File["/home/${user}/John"],
    notify  => Exec['start-smbd'],
  }
  exec { 'start-smbd':
    cwd     => "${binary_dir}/",
    command => 'sudo ./smbd -D',
    require => Exec['start-nmbd'],
  }
}
