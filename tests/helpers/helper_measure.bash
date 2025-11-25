
time_exec() {
    local start end elapsed
    start=$(date +%s%N)
    "$@" &> /dev/null
    local status=$?
    end=$(date +%s%N)
    elapsed=$(( (end - start) / 1000000 ))  # ms
    # echo "[$(date +%H:%M:%S)] '$*' took ${elapsed}ms" >&3
    echo "$elapsed"
    return $status
}

mean() {
  local sum=0
  for t in "$@"; do
    sum=$((sum + t))
  done
  echo $(( sum / $# ))
}

min() {
  local m=$1
  shift
  for t in "$@"; do
    (( t < m )) && m=$t
  done
  echo "$m"
}

max() {
  local m=$1
  shift
  for t in "$@"; do
    (( t > m )) && m=$t
  done
  echo "$m"
}
