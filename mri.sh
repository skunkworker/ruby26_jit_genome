#/bin/bash --login
source ~/.rvm/scripts/rvm
rvm ruby-2.6.0-rc1 do ruby main.rb -f real.error.large.fasta -k 15 --trash