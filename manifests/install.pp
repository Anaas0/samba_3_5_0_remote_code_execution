#
class samba_3_5_0_remote_code_execution::install{
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ], environment => [ 'http_proxy=172.22.0.51:3128', 'https_proxy=172.22.0.51:3128' ] }
  # SecGen Parameters
  #$secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $user = 'samba'#$secgen_parameters['leaked_username'][0]
  $user_home = "/home/${user}"
  $build_dir = '/opt/samba_3_5_0'
  $config_file_dir = '/usr/local/samba/lib'
  $test_dir = '/usr/local/samba/bin'
  $puppet_files_path = 'puppet:///modules/samba_3_5_0_remote_code_execution'
  $public_share = "/home/${user}/Public"

  # Proxy
  exec { 'set-nic-dhcp':
    command   => 'sudo dhclient ens3',
    notify    => Exec['set-sed'],
    logoutput => true,
  }
  exec { 'set-sed':
    command   => "sudo sed -i 's/172.33.0.51/172.22.0.51/g' /etc/systemd/system/docker.service.d/* /etc/environment /etc/apt/apt.conf /etc/security/pam_env.conf",
    notify    => User["${user}"],
    logoutput => true,
  }

  # Create user(s)
  user { "${user}":
    ensure     => present,
    uid        => '666',
    gid        => 'root',#
    home       => "${user_home}/",
    managehome => true,
    require    => Exec['set-sed'],
    notify     => Package['acl'],
  }

  # Install Packages
  # ensure_packages(['acl','xattr','gnutls-bin','libreadline-dev','make','gcc','autoconf']) For some reason, it causes issues if dependancies are installed this way in this module.
  package { 'acl':
    ensure  => installed,
    require => User["${user}"],
    notify  => Package['xattr'],
  }
  package { 'xattr':
    ensure  => installed,
    require => Package['acl'],
    notify  => Package['gnutls-bin'],
  }
  package { 'gnutls-bin':
    ensure  => installed,
    require => Package['xattr'],
    notify  => Package['libreadline-dev'],
  }
  package { 'libreadline-dev':
    ensure  => installed,
    require => Package['gnutls-bin'],
    notify  => Package['make'],
  }
  package { 'make':
    ensure  => installed,
    require => Package['libreadline-dev'],
    notify  => Package['gcc'],
  }
  package { 'gcc':
    ensure  => installed,
    require => Package['make'],
    notify  => Package['autoconf'],
  }
  package { 'autoconf':
    ensure  => installed,
    require => Package['gcc'],
    notify  => File["${build_dir}/"]
  }

  # Make install dir
  file { "${build_dir}/":
    ensure  => directory,
    owner   => $user,
    mode    => '0755',
    require => Package['autoconf'],
    notify  => File["${build_dir}/samba_3_5_0.tar.gz"],
  }

  # Copy tar ball to build dir
  file { "${build_dir}/samba_3_5_0.tar.gz":
    source  => 'puppet:///modules/samba_3_5_0_remote_code_execution/samba_3_5_0.tar.gz',
    owner   => $user,
    mode    => '0777',
    require => User["${user}"],
    notify  => Exec['mellow-file'],
  }

  # Extract
  exec { 'mellow-file':
    cwd     => "${build_dir}/",
    command => 'tar -zxf samba_3_5_0.tar.gz',
    creates => "${build_dir}/samba-3.5.0/",
    require => File["${build_dir}/samba_3_5_0.tar.gz"],
    notify  => Exec['gen-config'],
  }

  # Autogen
  exec { 'gen-config': # 4~ seconds
    cwd     => "${build_dir}/samba-3.5.0/source3/",
    command => 'sudo ./autogen.sh',
    require => Exec['mellow-file'],
    notify  => Exec['config-make'],
  }

  # Configure
  exec { 'config-make': # 50~ seconds
    cwd     => "${build_dir}/samba-3.5.0/source3/",
    command => 'sudo ./configure',
    require => Exec['gen-config'],
    notify  => Exec['make-build'],
  }

  # Make
  exec { 'make-build': # 330~ seconds. Just over default timeout - yes i timed each command.
    cwd     => "${build_dir}/samba-3.5.0/source3/",
    command => 'sudo make',
    timeout => 480, # 8 minutes to be safe.
    require => Exec['config-make'],
    notify  => Exec['make-install'],
  }

  # Make install
  exec { 'make-install': # 3~ seconds.
    cwd     => "${build_dir}/samba-3.5.0/source3/",
    command => 'sudo make install',
    require => Exec['make-build'],
    notify  => File["${config_file_dir}/smb.conf"],
  }

  # Copy smb.conf
  file { "${config_file_dir}/smb.conf":
    source  => 'puppet:///modules/samba_3_5_0_remote_code_execution/smb.conf',
    owner   => $user,
    mode    => '0755',
    require => Exec['make-install'],
    notify  => Exec['restart-networking'],
  }

  # Undo proxy settings
  ############################################## ~PROXY SETTINGS UNDO START~ ##############################################

  exec { 'restart-networking':
    command => 'sudo service networking restart',
    require => File["${config_file_dir}/smb.conf"],
    notify  => File["${public_share}"],
  }

  ##############################################  ~PROXY SETTINGS UNDO END~  ##############################################
}

