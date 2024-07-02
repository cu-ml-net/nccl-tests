#! /bin/bash

set -eux pipefail

TESTS=("all_gather" "all_reduce" "alltoall" "broadcast" "reduce" "reduce_scatter")
# TESTS=("all_reduce")
NCCL_TESTS_DIR=/root/nccl-tests/build
BASE_DIR=$(pwd)
OUTPUT_DIR=nccl_test
BASELINE=baseline.csv
WITH_FAULT=withFault.csv
NUM_TESTS=1
#COLLECTIVE_SIZE=45M
#NUM_ITERATIONS=500
COLLECTIVE_SIZES=("1M" "32M" "1G")
NUM_ITERATIONS=("20000" "1000" "32")
NUM_COLLECTIVES=2
NUM_NODES=5
NODES=node0,node1,node2,node3,node4
#NODES=node0,node1

# only in controller node, create file named "is_controller" in this same folder
# touch is_controller

# Create output directory if it does not exist, otherwise remove all files in the directory
# if [ ! -d $OUTPUT_DIR ]; then
#     mkdir $OUTPUT_DIR
# else
#     rm -rf $OUTPUT_DIR/*
# fi

# create output directory for each test
# for test in ${TESTS[@]}; do
#     mkdir -p ${OUTPUT_DIR}/${test}
# done

# write IP list to a file
#echo '["172.18.10.0", "172.18.10.1", "172.18.10.2", "172.18.10.3", "172.18.10.4", "172.18.10.5"]' > /root/ips.json

# run tests
for i in $(seq 1 ${NUM_TESTS}); do
    for test in ${TESTS[@]}; do
        echo "####### Running $test test iteration $i #######"
        for j in $(seq 0 ${NUM_COLLECTIVES}); do
            collective_size=${COLLECTIVE_SIZES[j]}
            iterations=${NUM_ITERATIONS[j]}
            # baseline
                mpirun --mca btl_tcp_if_include services0 -x NCCL_IB_HCA=mlx5_6 \
                    --allow-run-as-root -n ${NUM_NODES} --host ${NODES} \
                    ${NCCL_TESTS_DIR}/${test}_perf -b ${collective_size} \
                    -e ${collective_size} -g 1 -n ${iterations} \
                    -s ${BASE_DIR}/${OUTPUT_DIR}/${test}/${iterations}_${collective_size}_${BASELINE} \
            # fault
                mpirun --mca btl_tcp_if_include services0 -x NCCL_IB_HCA=mlx5_6 \
                    --allow-run-as-root -n ${NUM_NODES} --host ${NODES} \
                    ${NCCL_TESTS_DIR}/${test}_perf -b ${collective_size} \
                    -e ${collective_size} -g 1 -n ${iterations} \
                    -s ${BASE_DIR}/${OUTPUT_DIR}/${test}/${iterations}_${collective_size}_${WITH_FAULT} \
                    -j
    	done
    done
done
