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
  ensure_packages(['acl','xattr','gnutls-bin','libreadline-dev','make','gcc','autoconf'])

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
  exec { 'gen-config':
    cwd     => "${build_dir}/samba-3.5.0/source3/",
    command => 'sudo ./autogen.sh',
    require => Exec['mellow-file'],
    notify  => Exec['config-make'],
  }

  # Configure
  exec { 'config-make':
    cwd     => "${build_dir}/samba-3.5.0/source3/",
    command => 'sudo ./configure',
    require => Exec['gen-config'],
    notify  => Exec['make-build'],
  }

  # Make
  exec { 'make-build':
    cwd     => "${build_dir}/samba-3.5.0/source3/",
    command => 'sudo make',
    require => Exec['config-make'],
    notify  => Exec['make-install'],
  }

  # Make install
  exec { 'make-install':
    cwd     => "${build_dir}/samba-3.5.0/source3/",
    command => 'sudo make install',
    require => Exec['make-build'],
    notify  => File["${config_file_dir}/smb.conf"],
  }

  # Copy smb.conf
  file { "${config_file_dir}/smb.conf":
    source  => "${puppet_files_path}/smb.conf",
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
    notify  => File["/home/${user}/Public"],
  }

  ##############################################  ~PROXY SETTINGS UNDO END~  ##############################################
}

