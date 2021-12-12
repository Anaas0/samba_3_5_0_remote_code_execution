#
class samba_3_5_0_remote_code_execution::config{
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ], environment => [ 'http_proxy=172.22.0.51:3128', 'https_proxy=172.22.0.51:3128' ] }
  # SecGen Parameters
  # $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $user = 'samba'#$secgen_parameters['leaked_username'][0]
  $user_home = "/home/${user}"
  $build_dir = '/opt/samba_3_5_0/'
  $config_file_dir = '/usr/local/samba/lib'
  $test_dir = '/usr/local/samba/bin'

  # Create user(s)
  user { "${user}":
    ensure     => present,
    uid        => '666',
    gid        => 'root',#
    home       => "${user_home}/",
    managehome => true,
    notify     => File["${build_dir}/samba_3_5_0.tar.gz"],
  }

  # Create user shares

  # Set perms

  # Test the smb.conf

  # Start nmbd -D & smbd -D
}
