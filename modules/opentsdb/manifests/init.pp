class opentsdb {
	# install package dh-autoreconf, gnuplot
	package {"dh-autoreconf":
		ensure => "installed",
	}
	package {"gnuplot":
		ensure => "installed",
		require => Package["dh-autoreconf"],
	}
	# get files
	file { "opentsdb-${opentsdb_version}.tar.gz":
        	path => "${opentsdb_parent_dir}/opentsdb-${opentsdb_version}.tar.gz",
	        source => "puppet:///modules/opentsdb/opentsdb-${opentsdb_version}.tar.gz",
        	backup => false,
		require => [Package["gnuplot"],Class["hbase"]],
    	}

	exec { "opentsdb_untar":
        	command => "tar xzf opentsdb-${opentsdb_version}.tar.gz;",
       		cwd => "${opentsdb_parent_dir}",
		path => "/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
        	require => File["opentsdb-${opentsdb_version}.tar.gz"],
        	creates => "${opentsdb_parent_dir}/opentsdb-${opentsdb_version}",
    	}

	file { "opentsdb-reown-build":
        	path => "${opentsdb_parent_dir}/opentsdb-${opentsdb_version}",
       		backup => false,
        	recurse => true,
        	owner => $user,
        	group => $group,
        	require => Exec["opentsdb_untar"],
    	}

	file { "$opentsdb_home":
        	target => "${opentsdb_parent_dir}/opentsdb-${opentsdb_version}", 
        	ensure => symlink,
	        backup => false,
        	require => File["opentsdb-reown-build"],
        	owner => $user,
        	group => $group,
    	}
	file {"tsd":
		path => '/tmp/tsd',
		ensure => directory,
		owner => $user,
		group => $group,
	}
	## build opentsdb
	exec {"build_opentsdb":
		command => "./build.sh",
		cwd => $opentsdb_home,
		path => "/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
		require => [File["$opentsdb_home"], File["tsd"]],
		creates => "${opentsdb_home}/build",
	}

	#define logging paths
    	$log_path = $operatingsystem ? {
        	Darwin   => "/Users/${user}/Library/Logs/opentsdb/",
        	default => "/var/log/opentsdb/",
    	}

    	include opentsdb::copy_conf
    	include opentsdb::copy_services
/*
=begin
=end
*/
}

class opentsdb::copy_conf {
	file {"create_table":
		path => "${opentsdb_home}/src/create_table.sh",
		content => template("opentsdb/conf/create_table.sh.erb"),
        	owner => $user,
        	group => $group,
        	mode => 755,
        	ensure => file,
        	require => File["${opentsdb_home}"], 
	}
}
class opentsdb::copy_services {
	file {"start_opentsdb":
		path => '/etc/init.d/opentsdb',
		content => template("opentsdb/service/opentsdb.erb"),
		owner => $user,
		group => $group,
		mode => 755,
		ensure => file,
	#	require => File["${opentsdb_home}"], 
	}
}


