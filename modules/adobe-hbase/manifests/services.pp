# Class: services
#
# This module manages hbase services
#
# Parameters:
# Actions:
#   deploy service to /etc/init.d/
#   start/ enable services
# Requires:
#   an install of hbase
# Sample Usage:
#   include services::hbase-master
#   include services::hbase-regionserver
class services {
  # does nothing; used for auto-magic lookup
}

class services::all {
#  include services::hbase-master
#  include services::hbase-regionserver
#	include services::hbase-zookeeper
#	include services::hbase-master-backup
}

class services::hbase-master {
  service { "hbase-master":
    ensure => running,
    enable => true,
    pattern => "HMaster",
    require => [File["hbase-master-service"], File["$hbase_home"],Service["hbase-zookeeper"]],
  }
}
class services::hbase-master-backup {
  service { "hbase-master-backup":
    ensure => running,
    enable => true,
    pattern => "HMasterBackup",
    require => [File["hbase-master-backup-service"], File["$hbase_home"], Service["hbase-regionserver"]],
  }
}

class services::hbase-regionserver {
  service { "hbase-regionserver":
    ensure => running,
    enable => true,
    hasstatus => false,
    pattern => "HRegionServer",
    require => [File["hbase-regionserver-service"], File["$hbase_home"], Service["hbase-master"]],
  }
}
class services::hbase-zookeeper {
  service { "hbase-zookeeper":
    ensure => running,
    enable => true,
    hasstatus => false,
    pattern => "HZookeeper",
    require => [File["hbase-zookeeper-service"], File["$hbase_home"]]
  }
}

class services::hbase_dev {
  if $operatingsystem != Darwin {
    service { "hbase":
      ensure => running,
      enable => false,
    }
  } else {
    exec { "hbase_service":
      command => "hbase_service start",
      cwd => "/usr/bin/",
    }
  }
}

