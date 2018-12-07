

# class String
#   def blank?
#     self == ""
#   end
# end

# class Array
#   def blank?
#     self == []
#   end
# end


# class Node
#   attr_accessor :data, :edges

#   def initialize(data)
#     @data = data

#     # @edges = Set[]
#     # @edges = [] # because there can be multiple

#     prefix
#     suffix
#   end

#   # def add_edge(other_node)
#   #   @edges << other_node.data
#   # end

#   def prefix
#     @prefix ||= data[0...(data.length-1)]
#   end

#   def suffix
#     @suffix ||= data[1...(data.length)]
#   end
# end

# @nodes = []

# require 'byebug'

def print_26_cycle(cycle)

  strs = cycle.each_with_index.map do |edge,i|

    if i+1 == cycle.length
      edge.data
      # edge.from_node.data
    else
            edge.data[0]
      # edge.from_node.data[0]
    end

  end

  return strs.join
end

def reconstruct_string_from_kmer_composition(k:, kmer_string:)
  kmers = kmer_string.split("\n").select{|e| !e.blank?}

  kmers.each do |kmer|
    @nodes << Node.new(kmer)
  end
  an_node = @nodes.select{|n| @nodes.select{|y| n.prefix == y.suffix}.blank? }.first

  bn_node = @nodes.select{|n| @nodes.select{|y| n.suffix == y.prefix}.blank? }.first

  if an_node.nil? || bn_node.nil?
    puts "Not a valid set of kmers"
    return
  end

  cycle = [an_node]

  current_node = an_node


  while cycle.count < @nodes.count
      debugger if current_node.nil?

    next_node = @nodes.select{|node| node.prefix == current_node.suffix }.first

    cycle << next_node if !next_node.nil?
    current_node = next_node
  end

  puts "Complete Cycle"
  puts print_26_cycle(cycle)
end
