class services{
}
class services::opentsdb {
	service {"opentsdb":
		ensure => running,
		enable => false,
		require => [File["start_opentsdb"],File["$opentsdb_home"]],
	}
}
