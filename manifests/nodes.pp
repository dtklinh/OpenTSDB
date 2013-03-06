# nodes.pp
#
# module imports

## Tao them vao
import "virtual"
import "environment"
##import "adobe-mon"
#import "adobe-hbase"
#import "adobe-hbase/services"
import "adobe-hbase"
import "adobe-hbase/services"
import "opentsdb"
import "opentsdb/services"
import "tcollector"
import "tcollector/services"

import "adobe-hadoop"
import "adobe-hadoop/services"
#import "crankcase"
import "origin-server"
#import "mojolingo-openshift" 
#import "mojolingo-openshift/broker" 
##import "adobe-zookeeper"
##import "adobe-zookeeper/services"

##import "adobe-high-availability/drbd"
##import "adobe-high-availability/drbd-primary"
##import "adobe-high-availability/heartbeat"


# puppet roles for different servers
# zookeeper - server participating in a zookeeper quporum
# namenode - hadoop namenode. Will be setup with the hadoop namenode configuration and drbd / ha recipe for namenode failover
# datanode - hadoop datanode
# jobtracker - hadoop jobtracker
# tasktracker - hadoop tasktracker
# hbasemaster - hbase master server
# hbaseregion - hbase regionserver

#class drbd-base {
#    $virtual_ip = "192.168.1.1/24"
#    $resource_name = "r0"
#    $hostname_primary="server1"
#    $disk_dev_primary="/dev/sda2"
#    $ip_primary="192.168.1.12"
#    $hostname_secondary="server2"
#    $disk_dev_secondary="/dev/sda2"
#    $ip_secondary="192.168.1.13"
    
#    $hadoop_namenode_dir="/var/hadoop-namenode"
#    include drbd
#    include heartbeat
#    include mon
#}

# LA based machines

node base {
  include virtual_users, virtual_groups
  realize(Group["hadoop"], User["hduser"])
  $user="hduser"
  $group="hadoop"  
$hadoop_datastore = '/app/hadoop/tmp'
#  $hadoop_namenode_dir = "/var/hadoop_namenode/"
  #$hadoop_default_fs_name = "hdfs://server0:9000/"
#  $hadoop_datastore = ["/mnt/data_1/hadoop_data/", "/mnt/data_2/hadoop_data/"]
## che them
#  $hadoop_datastore_parents = 	["/mnt/data_1/", "/mnt/data_2/"]
#$hadoop_datastore_parents1 = 	"/mnt/data_1/"
#$hadoop_datastore_parents2 = 	"/mnt/data_2/"

#  $mapred_job_tracker = "server0:9001"
#  $hadoop_mapred_local = ["/mnt/data_1/hadoop_mapred_local/", "/mnt/data_2/hadoop_mapred_local/"]
  $environment="dev"
#  $hadoop_home="/home/hadoop/hadoop"
$hadoop_version= "1.0.3"
$hadoop_home="/usr/local/hadoop"
$hadoop_parent_dir= "/usr/local"
  $hadoop_from_source = false
  $hbase_home="/usr/local/hbase"
  $hbase_from_source = false
#  $zookeeper_home="/home/hadoop/zookeeper"
#  $zookeeper_from_source = false
	$master_hostname = master1311 
	$hbase_version= '0.92.1'
#	$hbase_parent_dir = "/home/hadoop"
	$hbase_parent_dir = "/usr/local"
#	$zookeeper_quorum = "l2,l3,l4,l5,l6,l7"
#    	$hbase_rootdir = "hdfs://l0:9000/hbase"
	$regionservers = "master1311,slave1311"
	## opentsdb
	$opentsdb_home = "/usr/local/opentsdb"
	$opentsdb_version = "1.0.1"
	$opentsdb_parent_dir = "/usr/local"
	## tcollector
	$tcollector_home = "/usr/local/tcollector"
	$tcollector_version = "1.0.1"
	$tcollector_parent_dir = "/usr/local"
	
  include environment
}
node common_variable {
	$user_home = "/home/hduser"
#	include virtual_users, virtual_groups
#	realize(Group["hadoop"], User["hduser"])
	$broker_ip = "192.168.122.22"
	$broker_hostname = "broker"
	$node_ip = "192.168.122.100"
	$node_hostname = "node1"

	$user="hduser"
  	$group="hadoop" 
	$crankcase_parent_dir = "/usr/local"
	$crankcase_home = "/usr/local/crankcase"
}
################## ORIGIN DEV TOOLS ########################
node origin_dev_tools_basic {
	$user="root" #"openshiftuser"
  	$group="root" #"openshift" 
#	$user_home = "/home/openshiftuser"
	$user_home = "/root"
	$origin_dev_tools_parent_dir = "/usr/local"
	$origin_dev_tools_home = "/usr/local/origin-dev-tools"
	$broker_ip = "192.168.122.118"
	$node_ip = "192.168.122.253"
	$hostname_node = "node0"
#	include virtual_users, virtual_groups
#	realize(Group["openshift"], User["openshiftuser"])
}
################################################################
class hadoop {
#    $hadoop_version="core-0.21.0-31"
	
#    $hadoop_parent_dir= "/home/hadoop"
    include hadoop  
	if $hostname == "$master_hostname" {
		include services::hadoop
	}
	else {
	#	include services::datanode
	}
#    include hadoop-jmx-metrics
}
class opentsdb {
	include opentsdb
	include services::opentsdb
}
class tcollector {
	include tcollector
	include services::tcollector
}

class hbase {
#    $hbase_version="0.21.0-38"
#	$hbase_version= '0.92.1'
#    $zookeeper_quorum = "l2,l3,l4,l5,l6,l7"
#    $hbase_rootdir = "hdfs://l0:9000/hbase"
#    $hbase_parent_dir = "/home/hadoop"
    include hbase
	if $hostname == "$master_hostname" {
		include services::hbase_dev
	}
#    include hbase-snmp-metrics
}

#class zookeeper {
#    $zookeeper_version = "3.2.1"
#    $zookeeper_parent_dir = "/home/hadoop"
#    $zookeeper_datastore = "/var/zookeeper_datastore"
#    $zookeeper_datastore_log = "/var/zookeeper_datastore_log"
#    include zookeeper
#}

node "slave1311" inherits base {
#  include drbd
#  include drbd-primary
  include hadoop
#  include hbase
#  include zookeeper
#  $zookeeper_myid = "2"  

#  include services::datanode
#  include services::hbase-master
#  include services::hbase-regionserver
#  include services::tasktracke
#  include services::zookeeper
#  include services::tasktracker
  }
node "master1311" inherits base{
	include hadoop
	include hbase
	include opentsdb
	include tcollector
#	service {"my_ntp":
#		ensure => running,
#		provider => "init",	
#	}	
}

############# OpenShift ###################
node "broker" inherits origin_dev_tools_basic{
#node "broker.example.com" {
#	include origin_server::copy
#	include origin_server::repo_conf
#	include origin_server::copy_rpm
#	include origin_server::install_required_packages
	include origin_server::local_build

#	include openshift
#	include openshift::broker
#	class {"openshift::broker":
#		domain => "example.com",
#		password => "badpassword",
#	}

	

#	include origin_server
#	include local_build
#	include broker_setup

#	exec{"haha":
#		command => "sudo su -c './devenv clone_addtl_repos master'",
#		cwd => "/usr/local/origin-dev-tools/build",
#		path => "/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin:/usr/local/origin-dev-tools/build", 
#	}
#	include crankcase   ## 0: common setup
#	include broker_setup  ## 1
#	include broker::register ## 4
}

node "node0" inherits origin_dev_tools_basic{



#	include origin_server::copy
#	include origin_server::repo_conf
#	include origin_server::copy_rpm
	include origin_server::install_required_packages
#	include origin_server::local_build
}
node "broker.example.com"{
}


