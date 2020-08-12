#!/bin/bash
# Copyright (c) Facebook, Inc. and its affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#
#WARNING: must have compiled PyTorch and caffe2

#check if extra argument is passed to the test
if [[ $# == 1 ]]; then
    dlrm_extra_option=$1
else
    dlrm_extra_option=""
fi
#echo $dlrm_extra_option
DATASET_PATH=/localdisk/dlrm_dataset
export KMP_BLOCKTIME=1
export KMP_AFFINITY="granularity=fine,compact,1,0"
export LD_PRELOAD="$HOME/.local/lib/libtcmalloc.so:${CONDA_PREFIX}/lib/libiomp5.so"
ncores=26
nsockets=0
numa_cmd="numactl --physcpubind=0-$((ncores-1))"

DNNL_VERBOSE=1 $numa_cmd python -u  dlrm_s_pytorch.py --num-batches=10 --arch-sparse-feature-size=128 --arch-mlp-bot="13-512-256-128" --arch-mlp-top="1024-1024-512-256-1" --max-ind-range=40000000 --data-generation=dataset --data-set=terabyte --raw-data-file=${DATASET_PATH}/day --processed-data-file=${DATASET_PATH}/processed.npz --loss-function=bce --round-targets=True --learning-rate=1.0 --mini-batch-size=2048 --print-freq=2048 --print-time --test-freq=102400 --test-mini-batch-size=16384 --test-num-workers=0 --memory-map --mlperf-logging --mlperf-auc-threshold=0.8025 --mlperf-bin-loader --mlperf-bin-shuffle --inference-only  --use-ipex --bf16 $dlrm_extra_option 2>&1 | tee run_terabyte_mlperf_pt.log

echo "done"
