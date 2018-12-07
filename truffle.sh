#/bin/bash --login
source ~/.rvm/scripts/rvm
rvm truffleruby do ruby main.rb -f real.error.large.fasta -k 15 --trash