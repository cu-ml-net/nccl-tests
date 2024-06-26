#! /bin/bash

set -eux pipefail

TESTS=("all_gather" "all_reduce" "alltoall" "broadcast" "reduce" "reduce_scatter")
# TESTS=("all_reduce")
NCCL_TESTS_DIR=/root/nccl-tests-dev/build
BASE_DIR=$(pwd)
OUTPUT_DIR=nccl_test
BASELINE=baseline.csv
WITH_FAULT=withFault.csv
NUM_TESTS=1
COLLECTIVE_SIZE=45M
NUM_ITERATIONS=500
NUM_NODES=2
NODES=node0,node1

# only in controller node, create file named "is_controller" in this same folder
touch is_controller

# Create output directory if it does not exist, otherwise remove all files in the directory
if [ ! -d $OUTPUT_DIR ]; then
    mkdir $OUTPUT_DIR
else
    rm -rf $OUTPUT_DIR/*
fi

# create output directory for each test
for test in ${TESTS[@]}; do
    mkdir -p ${OUTPUT_DIR}/${test}
done

# run tests
for i in $(seq 1 $NUM_TESTS); do
    for test in ${TESTS[@]}; do
        echo "##################################################"
        echo "### Running $test test iteration $i ###"
        echo "##################################################"
        # baseline
        mpirun --mca btl_tcp_if_include services0 -x NCCL_IB_HCA=mlx5_6 \
            --allow-run-as-root -n ${NUM_NODES} --host ${NODES} \
            ${NCCL_TESTS_DIR}/${test}_perf -b ${COLLECTIVE_SIZE} \
            -e ${COLLECTIVE_SIZE} -g 1 -n ${NUM_ITERATIONS} \
            -s ${BASE_DIR}/${OUTPUT_DIR}/${test}/${BASELINE}
    done
done