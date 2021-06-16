#!/bin/bash
# ===============================================================
#  Create by BumJo Kim.
#  Service Dept. Ssangyong Information & Communications Corp.
# ===============================================================

REPLICA_COUNT=2
MASTER_PORT=$1

if [ "${MASTER_PORT}" == "" ]; then
	echo "createRedisCluster.sh <masterPort>"
    exit 1
fi

ip=`ifconfig | grep "inet " | awk '{print $2}' | grep -v "127.0.0.1"`

node1=$ip

ipFirst=`echo "${ip}" | awk -F"." '{print $1 "." $2 "."$3}'`
ipLast=`echo "${ip}" | awk -F"." '{print $4}'`

node2=${ipFirst}"."$((ipLast+1))
node3=${ipFirst}"."$((ipLast+2))

echo "Ip List : ${node1}, ${node2}, ${node3}"

REDIS_IP_LIST=("${node1}" "${node2}" "${node3}")
SERVER_COUNT=${#REDIS_IP_LIST[@]}

echo "ExecuteCmd => redis-cli --cluster create \"${REDIS_IP_LIST[0]}\":\"$MASTER_PORT\" \"${REDIS_IP_LIST[1]}\":\"$MASTER_PORT\" \"${REDIS_IP_LIST[2]}\":\"$MASTER_PORT\""
redis-cli --cluster create "${REDIS_IP_LIST[0]}":"$MASTER_PORT" "${REDIS_IP_LIST[1]}":"$MASTER_PORT" "${REDIS_IP_LIST[2]}":"$MASTER_PORT"

for ip_index in ${!REDIS_IP_LIST[*]}; do
    MASTER_IP=${REDIS_IP_LIST[ip_index]}
    for ((replica_index=1; replica_index<=REPLICA_COUNT; replica_index++)); do
      SLAVE_IP=${REDIS_IP_LIST[(ip_index+replica_index) % $SERVER_COUNT]}
      SLAVE_PORT=$((MASTER_PORT+replica_index))

      masterId=`redis-cli -p $MASTER_PORT cluster nodes | grep "$MASTER_IP":"$MASTER_PORT" | grep master | awk '{print $1}'`
      echo "ExecuteCmd => redis-cli --cluster add-node \"$SLAVE_IP\":\"$SLAVE_PORT\" \"$MASTER_IP\":\"$MASTER_PORT\" --cluster-slave --cluster-master-id ${masterId}"
      redis-cli --cluster add-node "$SLAVE_IP":"$SLAVE_PORT" "$MASTER_IP":"$MASTER_PORT" --cluster-slave --cluster-master-id ${masterId}
    done
done

echo "ExecuteCmd => redis-cli --cluster add-node \"$SLAVE_IP\":\"$SLAVE_PORT\" \"$MASTER_IP\":\"$MASTER_PORT\" --cluster-slave --cluster-master-id $(redis-cli -p $MASTER_PORT cluster nodes | grep \"$MASTER_IP\":\"$MASTER_PORT\" | grep master | awk '{print $1}')"
redis-cli -p $MASTER_PORT cluster nodes
