class services {
}
class services::tcollector{
	service {"tcollector":
		ensure => running,
		enable => true,
		require => [File["start_tcollector"], File["$tcollector_home"]],
	}	
}
