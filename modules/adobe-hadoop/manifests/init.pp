# Class: hadoop
#
# This module manages hadoop
#
# Parameters:
#   $environment=dev|stage|production - used to read different conf files
#   $hadoop_home: home of hadoop (e.g. /home/hadoop)
#   $hadoop_version = version of Hadoop to deploy
#   $hadoop_parent_dir = location of the hadoop folder parent - where to extract the variables, create symlinks, etc
#   $hadoop_datastore = list of mount points to be used for the datanodes
#   $hadoop_namenode_dir = dfs.name.dir value
#   $hadoop_default_fs_name - htdfs://host:port/
#   $mapred_job_tracker - url for the jobtracker (host:port)
#
# Actions:
#  get archive, untar, symlink
#  configure hadoop
#  deploy init.d services
#
# Requires:
#  CentOS / MacOSX
#
# Sample Usage:
#
#  $hadoop_home=/home/hadoop/hadoop
#  $hadoop_datastore=["/var/hadoop_datastore", "/mnt/hadoop_store_2"]
#  $hadoop_version=0.21.0-SNAPSHOT
#  $hadoop_parent_dir=/home/hadoop
#  $hadoop_default_fs_name=hdfs://namenode:9000
#  
#  include hadoop
#  include services::hadoop-namenode
class hadoop {

    # get files
## copy file hadoop-1.0.3 to the hadoop parent directory (/usr/local/)
    file { "hadoop-${hadoop_version}.tar.gz":
      path => "${hadoop_parent_dir}/hadoop-${hadoop_version}.tar.gz",
##      source => "puppet:///repo/hadoop-${hadoop_version}.tar.gz",
	source => "puppet:///modules/adobe-hadoop/hadoop-${hadoop_version}.tar.gz",
      backup => false,
      owner => "root",
      group => "root",
	require => [Class["virtual_users"],Class["virtual_groups"]],
    }
#	package {"openjdk-6-jdk":
#		ensure => installed,
#	}
## untar the package and create hadoop home as /usr/local/hadoop-1.0.3    
    exec { "hadoop_untar":
        command => "tar xzf hadoop-${hadoop_version}.tar.gz; chown -R ${user}:${group} /usr/local/hadoop-${hadoop_version}",
        cwd => "${hadoop_parent_dir}/",
	path => "/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
        require => File["hadoop-${hadoop_version}.tar.gz"],
        creates => "${hadoop_parent_dir}/hadoop-${hadoop_version}",
    }
## change the owner of hadoop home
    file { "hadoop-reown-build":
        path => "${hadoop_parent_dir}/hadoop-${hadoop_version}",
        backup => false,
        recurse => true,
        owner => $user,
        group => $group,
        require => Exec["hadoop_untar"],
    }
## make a symlink between hadoop-1.0.3 and hadoop
    file { "$hadoop_home":
        target => "${hadoop_parent_dir}/hadoop-${hadoop_version}", 
        backup => false,
        ensure => symlink, 
        require => File["hadoop-reown-build"],
        owner => $user,
        group => $group,
    }

    file { "$hadoop_home/pids":
        path =>"$hadoop_home/pids",
        backup => false,
        ensure => directory,
        owner => $user,
        group => $group,
        mode => 644,
        require => File["$hadoop_home"]
    }   
## this is place that data is stored.
	file {["/app","/app/hadoop", "/app/hadoop/tmp"]:
		ensure => directory,
		owner => $user,
		group => $group,
		mode => 750,
	}
	
/*
=begin       
	file { "parents1":
	path => $hadoop_datastore_parents1,
        backup => false,
        ensure => directory,
        owner => $user,
        group => $group,
        mode => 644,
#	require => File["parents"],
    }
file { "parents2":
	path => $hadoop_datastore_parents2,
        backup => false,
        ensure => directory,
        owner => $user,
        group => $group,
        mode => 644,
#	require => File["parents"],
    }
    file { $hadoop_datastore:
        backup => false,
        ensure => directory,
        owner => $user,
        group => $group,
        mode => 644,
	require => [File["parents1"],File["parents2"]],
    }
    
    file { "/var/hadoop_namenode":
        backup => false,
        ensure => directory,
        owner => $user,
        group => $group,
        mode => 644,
    }        
    
=end
*/
    #define logging paths
    $log_path = $operatingsystem ? {
        Darwin   => "/Users/$user/Library/Logs/hadoop/",
        default => "/var/log/hadoop/",
    }

    include hadoop::copy_conf
    include hadoop::copy_services
}

class hadoop::copy_conf {
## In this class, we copy and adjust all the configuration in $hadoop_home/conf/
    #put the HDFS configuration
    file { "hdfs-site-xml":
        path => "${hadoop_home}/conf/hdfs-site.xml",
        content => template("adobe-hadoop/conf/${environment}/hdfs-site.xml.erb"),
        owner => $user,
        group => $group,
        mode => 644,
        ensure => file,
        require => File["$hadoop_home"], 
    }

    file { "core-site-xml":
        path => "${hadoop_home}/conf/core-site.xml",
        content => template("adobe-hadoop/conf/${environment}/core-site.xml.erb"),
        owner => $user,
        group => $group,
        mode => 644,
        ensure => file,
        require => File["$hadoop_home"], 
    }

    file { "mapred-site-xml":
        path => "${hadoop_home}/conf/mapred-site.xml",
        content => template("adobe-hadoop/conf/${environment}/mapred-site.xml.erb"),
        owner => $user,
        group => $group,
        mode => 644,
        ensure => file,
        require => File["$hadoop_home"], 
    }

    $java_home= $operatingsystem ?{
        Darwin => "/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0/Home/",
        redhat => "/usr/java/latest",
        CentOS => "/usr/java/latest",
        default => "/usr/lib/jvm/java-1.6.0-openjdk-amd64",
    }
    
    file { "hadoop-env":
        path => "${hadoop_home}/conf/hadoop-env.sh",
        content => template("adobe-hadoop/conf/${environment}/hadoop-env.sh.erb"),
        owner => $user,
        group => $group,
        mode => 644,
        ensure => file,
        require => File["$hadoop_home"], 
    }    

    file { "hadoop_log_folder":
        path => $log_path, 
        owner => $user,
        group => $group,
        mode => 644,
        ensure => directory, 
        require => File["$hadoop_home"], 
    }
/*
=begin
    file { "hadoop_log4j":
        path => "$hadoop_home/conf/log4j.properties",
        owner => $user,
        group => $group,
        mode => 644,
        content => template("adobe-hadoop/conf/${environment}/log4j.properties.erb"), 
        require => File["$hadoop_home"], 
    }
=end
*/
	if $hostname == 'master1311'{
	    file {"hadoop_masters":
        	path => "$hadoop_home/conf/masters",
	        owner => $user,
        	group => $group,
	        mode => 644,
        	content => template("adobe-hadoop/conf/${environment}/masters.erb"),         
	        require => File["$hadoop_home"], 
	    }

	    file {"hadoop_slaves":
        	path => "$hadoop_home/conf/slaves",
	        owner => $user,
        	group => $group,
	        mode => 644,
        	content => template("adobe-hadoop/conf/${environment}/slaves.erb"),         
	        require => File["$hadoop_home"], 
	    }
	}
	else {
		file {"hadoop_masters":
                path => "$hadoop_home/conf/masters",
                owner => $user,
                group => $group,
                mode => 644,
                content => "localhost",
                require => File["$hadoop_home"],
	        }
		file {"hadoop_slaves":
                path => "$hadoop_home/conf/slaves",
                owner => $user,
                group => $group,
                mode => 644,
                content => "localhost",
                require => File["$hadoop_home"],
            }

	}
}

class hadoop::copy_services {
    #install the hadoop services
	
 
    $init_d_path = $operatingsystem ?{
        Darwin => "/usr/bin/hadoop_service", #"/Users/${user}/Library/LaunchAgents/hadoop.launchd",
        default => "/etc/init.d/hadoop",
    }

    $init_d_template = $operatingsystem ?{
        Darwin => "hadoop/service/hadoop_service.erb", #"hadoop/service/hadoop.launchd.erb",
        default => "adobe-hadoop/service/hadoop_service.erb",
    }

    file { "hadoop-start-dfs-service":
        path => $init_d_path,
        content => template($init_d_template),
        ensure => file,
        owner => $user,
        group => $group,
        mode => 755
    }

    if $operatingsystem != Darwin {
        $os = $operatingsystem? {
            Ubuntu => "ubuntu",
            Debian => "ubuntu",
            default => "redhat",
        }

        file { "hadoop-namenode-service":
            path => "/etc/init.d/hadoop-namenode",
            content => template("adobe-hadoop/service/${os}/hadoop-namenode.erb"),
            ensure => file,
            owner => "root",
            group => "root",
            mode => 755
        }

        file { "hadoop-datanode-service":
            path => "/etc/init.d/hadoop-datanode",
            content => template("adobe-hadoop/service/${os}/hadoop-datanode.erb"),
            ensure => file,
            owner => "root",
            group => "root",
            mode => 755
        }    

        file { "hadoop-secondarynamenode-service":
            path => "/etc/init.d/hadoop-secondarynamenode",
            content => template("adobe-hadoop/service/${os}/hadoop-secondarynamenode.erb"),
            ensure => file,
            owner => "root",
            group => "root",
            mode => 755
        }

        file { "hadoop-jobtracker-service":
            path => "/etc/init.d/hadoop-jobtracker",
            content => template("adobe-hadoop/service/${os}/hadoop-jobtracker.erb"),
            ensure => file,
            owner => "root",
            group => "root",
            mode => 755
        }    

        file { "hadoop-tasktracker-service":
            path => "/etc/init.d/hadoop-tasktracker",
            content => template("adobe-hadoop/service/${os}/hadoop-tasktracker.erb"),
            ensure => file,
            owner => "root",
            group => "root",
            mode => 755
        }
    }
}

