# == Class: tomcat
#
# This module installs the Tomcat application server from available repositories on RHEL variants
#
# === Parameters:
#
# [*version*]
#   tomcat full version number (valid format: x.y.z)
# [*service_name*]
#   tomcat service name
# [*service_ensure*]
#   whether the service should be running (valid: 'stopped'|'running')
# [*service_enable*]
#   enable service (boolean)
# [*tomcat_native*]
#   install Tomcat Native library (boolean)
# [*extras*]
#   install extra libraries (boolean)
# [*enable_manager*]
#   install admin webapps (boolean)
# [*create_default_admin*]
#   create default admin user (boolean)
# [*admin_user*]
#   admin user name
# [*admin_password*]
#   admin user password
#
# see README file for a description of the other parameters
#
# === Actions:
#
# * Install tomcat
# * Configure main instance
# * Download extra libraries (optional)
#
# === Requires:
#
# * puppetlabs/stdlib module
# * puppetlabs/concat module
#
# === Sample Usage:
#
#  class { '::tomcat':
#    version      => '7.0.54',
#    service_name => 'tomcat7'
#  }
#
class tomcat (
  #----------------------------------------------------------------------------------
  # packages and service
  #----------------------------------------------------------------------------------
  $version               = $::tomcat::params::version,
  $service_name          = $::tomcat::params::service_name,
  $service_ensure        = 'running',
  $service_enable        = true,
  $tomcat_native         = false,
  $extras                = false,
  #----------------------------------------------------------------------------------
  # security and administration
  #----------------------------------------------------------------------------------
  $enable_manager        = true,
  $create_default_admin  = true,
  $admin_user            = 'tomcatadmin',
  $admin_password        = 'password',
  #----------------------------------------------------------------------------------
  # server configuration
  #----------------------------------------------------------------------------------
  $control_port          = 8005,
  # executors
  $threadpool_executor   = false,
  # http connector
  $http_connector        = true,
  $http_port             = 8080,
  $use_threadpool        = false,
  #----------------------------------------------------------------------------------
  # ssl connector  
  $ssl_connector         = false,
  $ssl_port              = 8443,
  #----------------------------------------------------------------------------------
  # ajp connector
  $ajp_connector         = true,
  $ajp_port              = 8009,
  #----------------------------------------------------------------------------------
  # engine
  $defaulthost           = 'localhost',
  #----------------------------------------------------------------------------------
  # host
  $hostname              = 'localhost',
  $jvmroute              = '',
  $autodeploy            = true,
  $deployOnStartup       = true,
  $undeployoldversions   = false,
  $unpackwars            = true,
  $singlesignon_valve    = false,
  $accesslog_valve       = true,
  #----------------------------------------------------------------------------------
  # jmx
  $jmx_listener          = false,
  $jmx_registry_port     = 8050,
  $jmx_server_port       = 8051,
  #----------------------------------------------------------------------------------
  # global configuration file
  #----------------------------------------------------------------------------------
  # defaults will be generated within the class if undefined in class parameters
  # for convenience reasons, since default tomcat folder names match the service name
  $catalina_base         = undef,
  $catalina_home         = undef,
  $jasper_home           = undef,
  $catalina_tmpdir       = undef,
  $catalina_pid          = undef,
  $java_home             = '/usr/lib/jvm/jre',
  $java_opts             = '-server',
  $catalina_opts         = '',
  $security_manager      = false,
  $tomcat_user           = 'tomcat',
  $lang                  = '',
  $shutdown_wait         = 30,
  $shutdown_verbose      = false,
  $custom_fragment       = '',
  #----------------------------------------------------------------------------------
  # log4j
  $log4j                 = false,
  $log4j_conf_type       = 'ini',
  $log4j_conf_source     = "puppet:///modules/${module_name}/log4j.properties") inherits tomcat::params {
  # generate parameters if undefined
  $catalina_base_real = $catalina_base ? {
    undef   => "/usr/share/${service_name}",
    default => $catalina_base
  }
  $catalina_home_real = $catalina_home ? {
    undef   => "/usr/share/${service_name}",
    default => $catalina_home
  }
  $jasper_home_real = $jasper_home ? {
    undef   => "/usr/share/${service_name}",
    default => $jasper_home
  }
  $catalina_tmpdir_real = $catalina_tmpdir ? {
    undef   => "/var/cache/${service_name}/temp",
    default => $catalina_tmpdir
  }
  $catalina_pid_real = $catalina_pid ? {
    undef   => "/var/run/${service_name}.pid",
    default => $catalina_pid
  }

  # get major version
  $array_version = split($version, '[.]')
  $maj_version = $array_version[0]

  # should we force download extras libs?
  if $log4j or $jmx_listener {
    $extras_real = true
  } else {
    $extras_real = $extras
  }

  # start the real action
  contain tomcat::install
  contain tomcat::config
  contain tomcat::service
  if $log4j {
    contain tomcat::log4j
    Class['::tomcat::install'] ->
    Class['::tomcat::log4j'] ~>
    Class['::tomcat::service']
  }
  if $extras_real {
    contain tomcat::extras
    Class['::tomcat::install'] ->
    Class['::tomcat::extras'] ~>
    Class['::tomcat::service']
  }
  Class['::tomcat::install'] ->
  Class['::tomcat::config'] ~>
  Class['::tomcat::service']
}