#Copyright (c) Facebook, Inc. and its affiliates.
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
if [ $1 == accuracy ]
then
echo "--------------------------------------------"
echo "-------------test int8 accuracy-------------"
echo "--------------------------------------------"
python dlrm_s_pytorch.py --do-int8-inference --inference-only --load-model=/home/haozhezh/dlrm/saving_model/dlrm_py.pt --arch-sparse-feature-size=16 --arch-mlp-bot="13-512-256-64-16" --arch-mlp-top="512-256-1" --data-generation=dataset --data-set=kaggle --processed-data-file=/lustre/dataset/dlrm/kaggleAdDisplayChallenge_processed.npz --loss-function=bce --round-targets=True --learning-rate=0.1 --mini-batch-size=128 --print-freq=1024 --print-time 
    echo "--------------------------------------------"
elif [ $1 == throughput ]
then
echo "--------------------------------------------"
echo "------test int8 performance throughput------"
echo "--------------------------------------------"
export KMP_BLOCKTIME=1
export KMP_AFFINITY=granularity=fine,compact,1,0
numactl --physcpubind=0-27 --membind=0 python dlrm_s_pytorch.py --mini-batch-size=16 --num-batches=1000 --data-generation=random --arch-mlp-bot=512-512-64 --arch-mlp-top=1024-1024-1024-1 --arch-sparse-feature-size=64 --arch-embedding-size=1000000-1000000-1000000-1000000-1000000-1000000-1000000-1000000 --num-indices-per-lookup=100 --arch-interaction-op=dot --numpy-rand-seed=727 --print-freq=100 --print-time --inference-only --do-int8-inference > log/int8_throughput0.log &
numactl --physcpubind=28-55 --membind=0 python dlrm_s_pytorch.py --mini-batch-size=16 --num-batches=1000 --data-generation=random --arch-mlp-bot=512-512-64 --arch-mlp-top=1024-1024-1024-1 --arch-sparse-feature-size=64 --arch-embedding-size=1000000-1000000-1000000-1000000-1000000-1000000-1000000-1000000 --num-indices-per-lookup=100 --arch-interaction-op=dot --numpy-rand-seed=727 --print-freq=100 --print-time --inference-only --do-int8-inference > log/int8_throughput1.log 
wait
python parser_log.py
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
  start_core_id=$((($1) * 4))
  end_core_id=$(($(($(($1 + 1)) * 4)) - 1))
  outf="log/model1_CPU_PT_instance$1.log"
  export KMP_BLOCKTIME=1
  export KMP_AFFINITY=granularity=fine,compact,1,0
  if [ $start_core_id -lt 28 ]
  then
    numa_cmd="numactl --physcpubind=$start_core_id-$end_core_id --membind=0"
  else
    numa_cmd="numactl --physcpubind=$start_core_id-$end_core_id --membind=1"
  fi
  cmd="$numa_cmd $dlrm_pt_bin $_args > $outf"
  #echo $cmd
  eval $cmd
}
for i in $(seq 0 13)
do
  run_one_instance $i & 
done
wait
python parser_log.py --real-time
echo "--------------------------------------------"
fi
