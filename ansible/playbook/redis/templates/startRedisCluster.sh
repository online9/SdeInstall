 #!/bin/bash
# ========================================================================
#  Create by BumJo Kim.
#  Application Service Dept. Ssangyong Information & Communications Corp.
# ========================================================================

nohup redis-server /data/servers/redis/master/redis_%{master}.conf & 
nohup redis-server /data/servers/redis/slave1/redis_%{slave1}.conf &
nohup redis-server /data/servers/redis/slave2/redis_%{slave2}.conf &
 