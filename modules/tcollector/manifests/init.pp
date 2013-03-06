class tcollector {
	# install package dh-autoreconf, gnuplot
	
	# get files
	file { "tcollector-${tcollector_version}.tar.gz":
        	path => "${tcollector_parent_dir}/tcollector-${tcollector_version}.tar.gz",
	        source => "puppet:///modules/tcollector/tcollector-${tcollector_version}.tar.gz",
        	backup => false,
		require => [Class["opentsdb"],Class["services::opentsdb"]],
	#	require => Package["gnuplot"],
    	}

	exec { "tcollector_untar":
        	command => "tar xzf tcollector-${tcollector_version}.tar.gz;",
       		cwd => "${tcollector_parent_dir}",
		path => "/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin",
        	require => File["tcollector-${tcollector_version}.tar.gz"],
        	creates => "${tcollector_parent_dir}/tcollector-${tcollector_version}",
    	}

	file { "tcollector-reown-build":
        	path => "${tcollector_parent_dir}/tcollector-${tcollector_version}",
       		backup => false,
        	recurse => true,
        	owner => $user,
        	group => $group,
        	require => Exec["tcollector_untar"]
    	}

	file { "$tcollector_home":
        	target => "${tcollector_parent_dir}/tcollector-${tcollector_version}", 
        	ensure => symlink,
	        backup => false,
        	require => File["tcollector-reown-build"],
        	owner => $user,
        	group => $group,
    	}
	

	#define logging paths
    	$log_path = $operatingsystem ? {
        	Darwin   => "/Users/${user}/Library/Logs/tcollector/",
        	default => "/var/log/tcollector/",
    	}

    	include tcollector::copy_conf
    	include tcollector::copy_services
/*
=begin
=end
*/
}
class tcollector::copy_conf{
	file {"startstop":
		path => "${tcollector_home}/startstop",
		content => template("tcollector/conf/startstop.erb"),
		owner => $user,
        	group => $group,
        	mode => 755,
        	ensure => file,
        	require => File["${tcollector_home}"], 
	}
}
class tcollector::copy_services {
	file {"start_tcollector":
		path => "/etc/init.d/tcollector",
		content => template("tcollector/service/tcollector.erb"),
		owner => $user,
        	group => $group,
        	mode => 755,
        	ensure => file,
	}
}



