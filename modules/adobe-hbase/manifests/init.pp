# Class: hbase
#
# This module manages hbase
#
# Parameters:
#   $hbase_version = version of HBase to deploy
#   $hbase_parent_dir = /home/hadoop
#   $zookeeper_quorum = "zk1,zk2,zk3"
#   $hbase_rootdir = hdfs://namenode:9000/hbase
# Actions:
#   unpack 
# Requires:
#   java_home custom fact
# Sample Usage:
#   include hbase
class hbase {

    # get files
    file { "hbase-${hbase_version}.tar.gz":
        path => "${hbase_parent_dir}/hbase-${hbase_version}.tar.gz",
        source => "puppet:///modules/adobe-hbase/hbase-${hbase_version}.tar.gz",
        backup => false,
	require => Class["hadoop"],
    }
    
    exec { "hbase_untar":
        command => "tar xzf hbase-${hbase_version}.tar.gz;",
        cwd => "${hbase_parent_dir}",
	path => "/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
        require => File["hbase-${hbase_version}.tar.gz"],
        creates => "${hbase_parent_dir}/hbase-${hbase_version}",
    }

    file { "hbase-reown-build":
        path => "${hbase_parent_dir}/hbase-${hbase_version}",
        backup => false,
        recurse => true,
        owner => $user,
        group => $group,
        require => Exec["hbase_untar"]
    }

    file { "$hbase_home":
        target => "${hbase_parent_dir}/hbase-${hbase_version}", 
	backup => false,
        ensure => symlink,
        require => File["hbase-reown-build"],
        owner => $user,
        group => $group,
    }

    #define logging paths
    $log_path = $operatingsystem ? {
        Darwin   => "/Users/${user}/Library/Logs/hbase/",
        default => "/var/log/hbase/",
    }

    include hbase::copy_conf
    include hbase::copy_services
	include hbase::copy_dev_services
}

class hbase::copy_conf {

    file { "hbase-site-xml":
        path => "${hbase_home}/conf/hbase-site.xml",
        content => template("adobe-hbase/conf/${environment}/hbase-site.xml.erb"),
        owner => $user,
        group => $group,
        mode => 644,
        ensure => file,
        require => File["${hbase_home}"], 
    }

    $java_home= $operatingsystem ?{
        Darwin => "/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home/",
        redhat => "/usr/java/latest",
        CentOS => "/usr/java/latest",
        default => "/usr/lib/jvm/java-1.6.0-openjdk-amd64",
    }
    
    file { "hbase-env":
        path => "${hbase_home}/conf/hbase-env.sh",
        content => template("adobe-hbase/conf/${environment}/hbase-env.sh.erb"),
        owner => $user,
        group => $group,
        mode => 644,
        ensure => file,
        require => File["$hbase_home"], 
    }
#	if $hostname == "master" {
		file { "hbase-regionservers":
			path => "${hbase_home}/conf/regionservers",
			content => template("adobe-hbase/conf/${environment}/hbase-regionservers.erb"),
			owner => $user,
			group => $group,
			mode => 644,
			ensure => file,
			require => File["$hbase_home"], 
	    	}
#	}
/*
	else {
		file { "hbase-regionservers":
			path => "${hbase_home}/conf/regionservers",
			content => 'localhost',
			owner => $user,
			group => $group,
			mode => 644,
			ensure => file,
			require => File["$hbase_home"], 
	    	}
	}
*/
    file { "hbase_log_folder":
        path => $log_path, 
        owner => $user,
        group => $group,
        mode => 644,
        ensure => directory, 
    }
/*
=begin
    file { "hbase_log4j":
        path => "${hbase_home}/conf/log4j.properties",
        owner => $user,
        group => $group,
        mode => 644,
        content => template("adobe-hbase/conf/${environment}/log4j.properties.erb"), 
        require => File["$hbase_home"], 
    }
=end
*/
## che them
	file { "hadoop-core-1.0.3":
		path => "${hbase_home}/lib/hadoop-core-1.0.3.jar",
		mode => 777,
		source => "puppet:///modules/adobe-hbase/hadoop-core-1.0.3.jar",
		require => File["$hbase_home"], 
	}
	file { "hadoop-core-1.0.0.jar":
		path => "${hbase_home}/lib/hadoop-core-1.0.0.jar",
		ensure => "absent",
		require => File["hadoop-core-1.0.3"],
	}
}

class hbase::copy_services {
    # install the service by copying a file:
    # this will not work on MacOS, so we safeguard against it
    if $operatingsystem != Darwin {
        file { "hbase-master-service":
            path => "/etc/init.d/hbase-master",
            content => template("adobe-hbase/service/hbase-master.erb"),
            backup => false,
            ensure => file,
            owner => "root",
            group => "root",
            mode => 755
        }

        file { "hbase-regionserver-service":
            path => "/etc/init.d/hbase-regionserver",
            content => template("adobe-hbase/service/hbase-regionserver.erb"),
            backup => false,
            ensure => file,
            owner => "root",
            group => "root",
            mode => 755
        }

        file { "hbase-thrift-service":
            path => "/etc/init.d/hbase-thrift",
            content => template("adobe-hbase/service/hbase-thrift.erb"),
            ensure => file,
            owner => "root",
            group => "root",
            mode => 755
        }
	file { "hbase-zookeeper-service":
		path => "/etc/init.d/hbase-zookeeper",
		content => template("adobe-hbase/service/hbase-zookeeper.erb"),
		ensure => file,
            	owner => "root",
	        group => "root",
        	mode => 755
	}
	file { "hbase-master-backup-service":
		path => "/etc/init.d/hbase-master-backup",
		content => template("adobe-hbase/service/hbase-master-backup.erb"),
		ensure => file,
            	owner => "root",
	        group => "root",
        	mode => 755
	}
    }
}

# copy a service helper for a dev machine
# you will need to adjust the $hbase_home to point to 
# hbase/target/.../.../
class hbase::copy_dev_services {
  $init_d_path = $operatingsystem ?{
    Darwin => "/usr/bin/hbase_service",
    default => "/etc/init.d/hbase",
  }

  $init_d_template = $operatingsystem ?{
    Darwin => "hbase/service/hbase_service.erb",
    default => "adobe-hbase/service/dev/hbase.erb",
  }

  file { "hbase-start-all-service":
    path => $init_d_path,
    content => template($init_d_template),
    ensure => file,
    owner => $user,
    group => $group,
    mode => 755
  }  
}
