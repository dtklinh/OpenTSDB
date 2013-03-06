Assume we have 2 machines (master and slave), and they could communicate each other without password.
In nodes.pp
Step 1: Set up and run service hadoop (in all nodes)
import adobe-hadoop
import adobe-hadoop/services

node "master" inherits base{
	include hadoop
}
node "slave" inherits base{
	include hadoop
}

Step 2: set up and run habse (in all nodes) 
import adobe-hbase
import adobe-hbase/services

node "master" inherits base{
        include hbase
}
node "slave" inherits base{
        include hbase
}

Step 3: set up and run OpenTSDB (master machine only)
import opentsdb
import opentsdb/services

node "master" inherits base{
        include opentsdb
}

Step 4: set up and run tcollector (master machine only)
import tcollector   
import tcollector/services

node "master" inherits base{
        include tcollector
}


