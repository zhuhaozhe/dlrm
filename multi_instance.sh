#Copyright (c) Facebook, Inc. and its affiliates.
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
ncores=4 #28 #12 #6
nsockets="0"
dlrm_c2_bin="python dlrm_s_pytorch.py"
data=random #synthetic
rand_seed=727

#Model param
mb_size=16 #2048 #1024 #512 #256
nbatches=10000 #500 #100
print_freq=$((nbatches/10))
bot_mlp="512-512-64"
top_mlp="1024-1024-1024-1"
emb_size=64
nindices=100
emb="1000000-1000000-1000000-1000000-1000000-1000000-1000000-1000000"
interaction="dot"

_args="--mini-batch-size="${mb_size}\
" --num-batches="${nbatches}\
" --data-generation="${data}\
" --arch-mlp-bot="${bot_mlp}\
" --arch-mlp-top="${top_mlp}\
" --arch-sparse-feature-size="${emb_size}\
" --arch-embedding-size="${emb}\
" --num-indices-per-lookup="${nindices}\
" --arch-interaction-op="${interaction}\
" --numpy-rand-seed="${rand_seed}\
" --print-freq="${print_freq}\
" --print-time"\
" --inference-only"\
" --do-int8-inferenc" 

# CPU Benchmarking
echo "--------------------------------------------"
echo "CPU Benchmarking - running on $ncores cores"
echo "--------------------------------------------"
echo "-------------------------------"
echo "Running PT (log file: $outf)"
echo "-------------------------------"
function run_one_instance()
{
  start_core_id=$((($1) * 4))
  end_core_id=$(($(($(($1 + 1)) * 4)) - 1))
  outf="log/model1_CPU_PT_instance$1.log"
  export KMP_BLOCKTIME=1
  export KMP_AFFINITY=granularity=fine,compact,1,0
  numa_cmd="numactl --physcpubind=$start_core_id-$end_core_id"
  cmd="$numa_cmd $dlrm_c2_bin $_args > $outf"
  echo $cmd
  eval $cmd
}
for i in $(seq 0 13)
do
  run_one_instance $i & 
done
wait
