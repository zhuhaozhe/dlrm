#Copyright (c) Facebook, Inc. and its affiliates.
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
if [ $1 == accuracy ]
then
echo "--------------------------------------------"
echo "-------------test int8 accuracy-------------"
echo "--------------------------------------------"
python dlrm_s_pytorch.py --do-int8-inference --inference-only --load-model=/lustre/dataset/dlrm/dlrm_py.pt --arch-sparse-feature-size=16 --arch-mlp-bot="13-512-256-64-16" --arch-mlp-top="512-256-1" --data-generation=dataset --data-set=kaggle --processed-data-file=/lustre/dataset/dlrm/kaggleAdDisplayChallenge_processed.npz --loss-function=bce --round-targets=True --learning-rate=0.1 --mini-batch-size=128 --print-freq=1024 --print-time 
    echo "--------------------------------------------"
elif [ $1 == throughput ]
then
echo "--------------------------------------------"
echo "------test int8 performance throughput------"
echo "--------------------------------------------"
ncoros=4 #28 #12 #6
nsockets="0"
dlrm_pt_bin="python dlrm_s_pytorch.py"
data=random #synthetic
rand_seed=727

#Model param
mb_size=16 #2048 #1024 #512 #256
nbatches=1000 #500 #100
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
" --do-int8-inference"
# CPU Benchmarking"
function run_one_instance()
{
  start_core_id=$1
  outf="log/model1_CPU_PT_instance$1.log"
  export KMP_BLOCKTIME=1
  export KMP_AFFINITY=granularity=fine,compact,1,0
  numa_cmd="numactl --physcpubind=$1"
  cmd="$numa_cmd $dlrm_pt_bin $_args > $outf"
  #echo $cmd
  eval $cmd
}
for i in $(seq 0 27)
do
  run_one_instance $i &
done
wait
python parser_log.py
echo "--------------------------------------------"


echo "--------------------------------------------"
else
echo "--------------------------------------------"
echo "-------test int8 performance realtime-------"
echo "--------------------------------------------"
ncoros=4 #28 #12 #6
nsockets="0"
dlrm_pt_bin="python dlrm_s_pytorch.py"
data=random #synthetic
rand_seed=727

#Model param
mb_size=16 #2048 #1024 #512 #256
nbatches=1000 #500 #100
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
" --do-int8-inference" 
# CPU Benchmarking"
function run_one_instance()
{
  start_core_id=$1
  outf="log/model1_CPU_PT_instance$1.log"
  export KMP_BLOCKTIME=1
  export KMP_AFFINITY=granularity=fine,compact,1,0
  numa_cmd="numactl --physcpubind=$1"
  cmd="$numa_cmd $dlrm_pt_bin $_args > $outf"
 #echo $cmd
  eval $cmd
}
for i in $(seq 0 27)
do
  run_one_instance $i & 
done
wait
python parser_log.py --real-time
echo "--------------------------------------------"
fi
