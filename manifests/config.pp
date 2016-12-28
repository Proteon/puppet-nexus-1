# === Class: nexus::config
#
# Configure nexus.
#
# === Parameters
#
# NONE
#
# === Examples
#
# class{ 'nexus::config': }
#
# === Authors
#
# Tom McLaughlin <tmclaughlin@hubspot.com>
#
# === Copyright
#
# Copyright 2013 Hubspot
#
class nexus::config(
  $version           = $::nexus::version,
  $nexus_root        = $::nexus::nexus_root,
  $nexus_home_dir    = $::nexus::nexus_home_dir,
  $nexus_user        = $::nexus::nexus_user,
  $nexus_group       = $::nexus::nexus_group,
  $nexus_host        = $::nexus::nexus_host,
  $nexus_port        = $::nexus::nexus_port,
  $nexus_context     = $::nexus::nexus_context,
  $nexus_work_dir    = $::nexus::nexus_work_dir,
  $nexus_data_folder = $::nexus::nexus_data_folder,
  $nexus_min_memory  = $::nexus::nexus_min_memory,
  $nexus_max_memory  = $::nexus::nexus_max_memory,
) {

  if $version !~ /\d.*/ or versioncmp($version, '3.1.0') >= 0 {
    # Per the Sonatype documentation the custom nexus properties file is
    # {karaf.data}/etc/nexus.properties where {karaf.data} is the work dir
    $conf_path = 'etc/nexus.properties'
    $nexus_properties_file = "${nexus_work_dir}/${conf_path}"
  }
  elsif versioncmp($version, '3.0.0') >= 0 {
    $conf_path = 'etc/org.sonatype.nexus.cfg'
    $nexus_properties_file = "${nexus_root}/${nexus_home_dir}/${conf_path}"
  } else {
    $conf_path = 'conf/nexus.properties'
    $nexus_properties_file = "${nexus_root}/${nexus_home_dir}/${conf_path}"
  }
  $nexus_data_dir = "${nexus_root}/${nexus_home_dir}/data"

  # Nexus >=3.x do no necesarily have a properties file in place to
  # modify. Make sure that there is at least a minmal file there
  file { $nexus_properties_file:
    ensure =>  present,
  }
  case $version {
    /^2\.\d+\.\d+$/: {
      $nexus_properties_file = "${nexus_home}/conf/nexus.properties"
      $nexus_data_dir = "${nexus_home}/data"

      file_line{ 'nexus-application-host':
        path  => $nexus_properties_file,
        match => '^application-host',
        line  => "application-host=${nexus_host}"
      }

      file_line{ 'nexus-application-port':
        path  => $nexus_properties_file,
        match => '^application-port',
        line  => "application-port=${nexus_port}"
      }

      file_line{ 'nexus-webapp-context-path':
        path  => $nexus_properties_file,
        match => '^nexus-webapp-context-path',
        line  => "nexus-webapp-context-path=${nexus_context}"
      }

      file_line{ 'nexus-work':
        path  => $nexus_properties_file,
        match => '^nexus-work',
        line  => "nexus-work=${nexus_work_dir}"
      }
    }
    /^3\.0\.\d+$/: {
      $nexus_properties_file = "${nexus_home}/etc/org.sonatype.nexus.cfg"
      $nexus_data_dir = "${nexus_home}/data"

      file_line{ 'nexus-application-host':
        path  => $nexus_properties_file,
        match => '^application-host',
        line  => "application-host=${nexus_host}"
      }

      file_line{ 'nexus-application-port':
        path  => $nexus_properties_file,
        match => '^application-port',
        line  => "application-port=${nexus_port}"
      }

      file_line{ 'nexus-webapp-context-path':
        path  => $nexus_properties_file,
        match => '^nexus-webapp-context-path',
        line  => "nexus-webapp-context-path=${nexus_context}"
      }

      file_line{ 'nexus-work':
        path  => $nexus_properties_file,
        match => '^nexus-work',
        line  => "nexus-work=${nexus_work_dir}"
      }
    }
    default: {
      $nexus_properties_file = "${nexus_work_dir}/etc/nexus.properties"
      $nexus_data_dir = "${nexus_work_dir}/data"
      $nexus_rc_file = "${nexus_home}/bin/nexus.rc"
      $nexus_vmoptions_file = "${nexus_home}/bin/nexus.vmoptions"

      file { "${nexus_work_dir}/etc":
        ensure => directory,
        owner   => $nexus_user,
        group   => $nexus_group,
        mode    => '0755',
      }

      file { $nexus_properties_file:
        ensure  => present,
        owner   => $nexus_user,
        group   => $nexus_group,
        mode    => '0644',
        content => template('nexus/nexus.properties.erb')
      }

      file_line{ 'nexus-rc':
        path  => $nexus_rc_file,
        match => '^#run_as_user=""',
        line  => "run_as_user=\"${nexus_user}\""
      }

      file_line{ 'nexus-xms':
        path  => $nexus_vmoptions_file,
        match => '^-Xms',
        line  => "-Xms${nexus_min_memory}"
      }

      file_line{ 'nexus-xmx':
        path  => $nexus_vmoptions_file,
        match => '^-Xmx',
        line  => "-Xmx${nexus_max_memory}"
      }

      file_line{ 'nexus-karaf-data':
        path  => $nexus_vmoptions_file,
        match => '^-Dkaraf.data',
        line  => "-Dkaraf.data=${nexus_work_dir}"
      }

      file_line{ 'nexus-tmp-dir':
        path  => $nexus_vmoptions_file,
        match => '^-Djava.io.tmpdir',
        line  => "-Djava.io.tmpdir=${nexus_work_dir}/tmp"
      }

      file_line{ 'nexus-log-file':
        path  => $nexus_vmoptions_file,
        match => '^-XX:LogFile',
        line  => "-XX:LogFile=${nexus_work_dir}/log/jvm.log"
      }
    }
  }

  if $nexus_data_folder {
    file{ $nexus_data_dir :
      ensure => 'link',
      target => $nexus_data_folder,
      force  => true,
      notify => Service['nexus']
    }
  }
}
