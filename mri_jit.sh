#/bin/bash --login

#   jit             JIT compiler (default: disabled)
# JIT options (experimental):
#   --jit-warnings  Enable printing JIT warnings
#   --jit-debug     Enable JIT debugging (very slow)
#   --jit-wait      Wait until JIT compilation is finished everytime (for testing)
#   --jit-save-temps
#                   Save JIT temporary files in $TMP or /tmp (for testing)
#   --jit-verbose=num
#                   Print JIT logs of level num or less to stderr (default: 0)
#   --jit-max-cache=num
#                   Max number of methods to be JIT-ed in a cache (default: 1000)
#   --jit-min-calls=num
#                   Number of calls to trigger JIT (for testing, default: 5)


source ~/.rvm/scripts/rvm
rvm ruby-2.6.0-rc1 do ruby --jit --jit-save-temps main.rb -f real.error.large.fasta -k 15 --trash