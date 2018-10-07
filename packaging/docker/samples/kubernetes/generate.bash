#! /bin/bash

script_dir=$(dirname $0)
if [[ "$1" == "coordinators" ]]; then
	count=$2
	: > $script_dir/config/coordinators.yaml
	for index in $(seq 1 $count); do
		sed -e "s/\$index/$index/g" $script_dir/config_templates/coordinators_template.yaml >> $script_dir/config/coordinators.yaml
	done
	echo "Generated $script_dir/config/coordinators.yaml"
elif [[ "$1" == "cluster" ]]; then
	cluster_name=$2
	replica_count=$3
	coordinator_count=$4
	if [[ -z "$coordinator_count" ]]; then
		coordinator_count=$replica_count
	fi
	cluster_name_sanitized=$(echo $cluster_name | sed -e 's/[^0-9a-zA-z]//g')
	cluster_file="$cluster_name_sanitized:init@"
	for index in $(seq 1 $coordinator_count); do
		coordinator_ip=$(kubectl get services/fdb-coordinators-$index -o go-template='{{(index .spec.clusterIP)}}')
		cluster_file="$cluster_file$coordinator_ip:4500"
		if [[ $index -ne $coordinator_count ]]; then
			cluster_file="$cluster_file,"
		fi
	done
	sed -e "s/\$cluster_name/$cluster_name/g" $script_dir/config_templates/cluster_template.yaml \
		| sed -e "s/\$replica_count/$replica_count/g" \
		| sed -e "s/\$cluster_file/$cluster_file/g" \
		> $script_dir/config/$cluster_name.yaml
	echo "Generate $script_dir/config/$cluster_name.yaml"
else
	echo "Unknown command $1"
	exit 1
fi