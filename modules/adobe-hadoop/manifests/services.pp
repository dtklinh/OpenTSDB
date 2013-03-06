class services {
  # do nothing, magic lookup helper
#	include services::namenode, services::secondarynamenode, services::datanode, services::jobtracker, services::tasktracker
	
}
class services::hadoop {
	service { "hadoop":
		ensure => running,
		enable => true,
		require => [File["hadoop-start-dfs-service"], File["$hadoop_home"]],
	}
}
class services::namenode {
    service { "hadoop-namenode":
        ensure => running,
        enable => true,
        require => [File["hadoop-namenode-service"], File["$hadoop_home"]]
    }
}

class services::secondarynamenode {
    service { "hadoop-secondarynamenode":
        ensure => running,
        enable => true,
        require => [File["hadoop-secondarynamenode-service"], File["$hadoop_home"], Service["hadoop-datanode"]],
    }
}

class services::datanode {
    service { "hadoop-datanode":
        ensure => running,
        enable => true,
        require => [File["hadoop-datanode-service"], File["$hadoop_home"], Service["hadoop-namenode"]],
    }
}

class services::jobtracker {
    service { "hadoop-jobtracker":
##        ensure => running,
	ensure => stopped,
        enable => false,
        require => [File["hadoop-jobtracker-service"], File["$hadoop_home"]]
    }
}

class services::tasktracker {
    service { "hadoop-tasktracker":
##        ensure => running,
	ensure => stopped,
        enable => false,
        require => [File["hadoop-tasktracker-service"], File["$hadoop_home"]]
    }
}

