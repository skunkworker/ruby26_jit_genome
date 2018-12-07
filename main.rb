
require './load_genes'
require './p26'
require 'optparse'
require 'benchmark'

# A = adenine
# C = cytosine
# G = guanine
# T = thymine
# R = G A (purine)
# Y = T C (pyrimidine)
# K = G T (keto)
# M = A C (amino)
# S = G C (strong bonds)
# W = A T (weak bonds)
# B = G T C (all but A)
# D = G A T (all but C)
# H = A C T (all but G)
# V = G C A (all but T)
# N = A G C T (any)

class String
  def blank?
    self == ""
  end
end

class Array
  def blank?
    self == []
  end
end

class Datastore
  attr_reader :nodes, :edges

  def initialize
    @nodes = []
    @nodes_hash = {}

    @edges = []

    @edges_to_hash = {} # hash of edges with their from node
    @edges_from_hash = {} # hash of edges going to a node

    @edges_from_and_to_hash = {}
  end

  def get_edges(node, type: :indegree, count: false)
    if type == :outdegree || type == :degree
      # look for other to node
      found_edges = @edges_from_hash[node.data]
    else
      found_edges = @edges_to_hash[node.data]
    end

    if count
      if found_edges.nil?
        return 0
      end
      return (found_edges.count || 0)
    else
      return found_edges || []
    end
  end

  def add_node(data)
    if found_node = @nodes_hash[data]
      return found_node
    end

    new_node = Node.new(data)
    @nodes << new_node
    @nodes_hash[data] = new_node

    new_node
  end

  def remove_path(path)

    path.each_with_index do |edge, index|

      if index == 0
        remove_edge(edge, direction: :from)
        # remove self edge only
      elsif index == (path.count-1)
        remove_edge(edge, direction: :to)

        remove_node edge.from_node
        # at the end
      else
        remove_node edge.from_node
        remove_edge edge
        # we are in the middle.
      end

    end

  end

  def add_to_array_in_hash(hash,key:,obj:)
    (hash[key] ||= []) << obj
  end

  def add_edge(from:, to:)
    key = [from.data, to.data].join(";")

    if existing_edge = @edges_from_and_to_hash[key]
      existing_edge.add_weight

      return existing_edge
    end

    from_key = from.data
    to_key = to.data


    edge = NodeEdge.new(from: from, to: to)
    # from_node.add_edge edge

    @edges << edge

    add_to_array_in_hash(@edges_from_hash, key: from_key, obj: edge)
    add_to_array_in_hash(@edges_to_hash, key: to_key, obj: edge)

    @edges_from_and_to_hash[key] = edge

    edge
  end

  private

  def remove_edge(edge, direction: :both)

    if direction == :both || direction == :from
      from_key = edge.from_node.data

      @edges_from_hash[from_key].delete edge
    end

    if direction == :both || direction == :to
      to_key = edge.to_node.data
      @edges_to_hash[to_key].delete edge
    end

  end

  def remove_node(node)
    @nodes.delete node
    @nodes_hash[node.data] = nil
  end

end


class NodeEdge
  attr_accessor :from_node, :to_node

  attr_reader :walked

  attr_reader :weight

  def initialize(from:, to:)
    @from_node = from
    @to_node = to

    @weight = 1

    @walked = false
  end

  def can_walk?
    !to_node.walked
  end

  def reset_walked
    @walked = false
    to_node.reset_walked
  end

  def walk!
    @walked = true
    to_node.walk!
    return to_node
  end

  def print
    [from_node,to_node].map(&:data).join(" -> ")
  end

  def add_weight
    @weight +=1
  end

  def inspect
    if walked
      walked_str = "{#{@weight}} (walked)"
    else
      walked_str = "{#{@weight}} (not walked)"
    end
    [from_node,to_node].map(&:data).join(" -> ") + walked_str
  end

  def inspect_inside_node
    if walked
      walked_str = "##{@weight} (walked)"
    else
      walked_str = "##{@weight} (not walked)"
    end

    " -> " + to_node.data + walked_str
  end
end

def create_edge(from:, to:)
  $datastore.add_edge(from:from,to:to)
end

class Node
  attr_accessor :data
  attr_reader :walked


  def initialize(data)

    @data = data

    @walked = false

    prefix
    suffix
  end

  def edges
    $datastore.get_edges(self, type: :outdegree)
  end

  def unwalked_edges
    edges.select{|e| e.can_walk? }
  end

  def sample_unwalked_edge
    unwalked_edges.sample
  end

  def unwalked_edges_count
    unwalked_edges.count
  end

  def reset_edges
    edges.each(&:reset_walked)
  end

  def edges_count
    edges.count
  end

  def inspect
    "Node{#{self.object_id}}(#{data}) (#{indegree},#{degree}) # edges(#{edges.count}): #{edges.map(&:inspect_inside_node).join(",")};"
  end

  def degree
    $datastore.get_edges(self, type: :outdegree, count: true)
  end

  def indegree
    $datastore.get_edges(self, type: :indegree, count: true)
  end

  def prefix
    @prefix ||= data[0...(data.length-1)]
  end

  def suffix
    @suffix ||= data[1...(data.length)]
  end

  def walk!
    @walked = true
  end

  def reset_walked
    @walked = false
  end

  def one_in_one_out
    degree == 1 && indegree == 1
  end

  def walkable?
    @walked
  end

end

def add_node(data:)
  $datastore.add_node data
end

def reset_nodes
  $datastore.nodes.each(&:reset_edges)
end

def print_cycle_arrow(cycle)
  return "Empty Graph" if cycle.nil? || cycle.blank?
  starting_node = cycle.first.from_node

  nodes = cycle.map(&:from_node)
  nodes << cycle.last.to_node

  nodes.map(&:data).join("->")
end

def print_cycle(cycle)
  if cycle.length == 1
    return cycle.first.from_node.data[0]+cycle.first.to_node.data
  end

  strs = cycle.each_with_index.map do |edge,i|
    if i + 1 == cycle.length # at last node
      edge.from_node.data[0]+edge.to_node.data
    else
      edge.from_node.data[0]
    end
  end

  return strs.join
end

def all_edges_walked?

  all_nodes.each do |node|
    return false if !node.walkable?
  end

  return true
end

def all_nodes
  $datastore.nodes
end


class BadStartingNodeError < StandardError
end

#  from https://math.stackexchange.com/questions/1871065/euler-path-for-directed-graph
#
#  a) There should be a single vertex in graph which has (indegree+1==outdegree), lets call this vertex 'an'.
# b) There should be a single vertex in graph which has (indegree==outdegree+1), lets call this vertex 'bn'.
# c) Rest all vertices should have (indegree==outdegree)
# If either of the above condition fails Euler Path can't exist.
def find_starting_node(k:)
  all_dest_nodes = all_nodes.map{|n| n.edges.map{|e| e.to_node.data}}.flatten

  # try for perfect an_node

  perfect_an_node = all_nodes.select{|n| n.indegree == 0 && n.degree == 1 }.first
  puts "found perfect an_node #{perfect_an_node.inspect} " if !perfect_an_node.nil?

  an_node = all_nodes.select{|n| n.indegree + 1 == n.degree }.first
  $an_nodes = all_nodes.select{|n| n.indegree + 1 == n.degree }

  $bn_nodes = all_nodes.select{|n| n.indegree == n.degree + 1 }

  if !an_node.nil?
    # puts "Found an_node #{an_node.inspect}"
    # puts "Found bn_node #{bn_node.inspect}"
    puts "Found an_node #{an_node.inspect}"
    return an_node
  else
    puts "Choosing random starting node"
    all_nodes.sample
  end

end

def try_walk(i:0, k:, starting_node:)
  cycle = []
  current_node = starting_node

  ending_node = all_nodes.select{|n| n.edges_count == 0}.first

  i = 0

  current_node.walk!

  failed_walks = []

  current_best_path = []
  current_best_path_count = 0

  while !all_edges_walked?

    current_edge = current_node.sample_unwalked_edge


    if current_edge.nil?
      if all_edges_walked?
        return cycle
      else
        i += 1

        new_node = @find_new_partial_node.call

        # puts "Current traversal: #{cycle.size} backward count: #{i}"
        last_edge = cycle.pop

        raise BadStartingNodeError if last_edge.nil?

        last_edge.reset_walked

        cycle_before = cycle.dup

        while last_edge.from_node != new_node

          last_edge = cycle.pop

          # puts "walking back"

          if last_edge.nil?
            if cycle_before.count > current_best_path_count
              current_best_path = cycle_before
              current_best_path_count = cycle_before.count
              puts "new best count path #{current_best_path_count}, total node count: #{all_nodes.count}, total edges count: #{$datastore.edges.count}"

              $partial_paths << {count: cycle_before.count, path: cycle_before, starting_node: starting_node}
            end
            #

          end

          raise BadStartingNodeError if last_edge.nil?

          last_edge.reset_walked
        end

        # puts "going new direction"

        current_edge = new_node.sample_unwalked_edge

      end

    end
    cycle << current_edge

    current_node = current_edge.walk!
  end

  return cycle, nil
end

def find_nodes_by_prefix(str)
  all_nodes.select{|n| n.prefix == str}
end

def find_eulerian_cycle_in_graph(nodes)

  k = @k

  find_starting_node(k: k)

  if $an_nodes.count > 1
    puts "multiple starting nodes #{$an_nodes.count}"
  end

  i = 0

  new_node = all_nodes.first

  $an_nodes.each_with_index do |an_node, an_node_index|

    begin

    cycle, new_node = try_walk(i:i, k:k, starting_node: an_node)
    if cycle && !cycle.blank? && all_edges_walked?
      # debugger if !all_edges_walked?

      return print_cycle(cycle)
      # break
    else
      puts "bad cycle #{print_cycle(cycle)}" if cycle != nil
      i += 1
      # puts "Iteration: #{i}"
    end

    rescue BadStartingNodeError => e
      puts "Bad Starting Node #{an_node_index} of #{$an_nodes.count}"

      $datastore.edges.each{|e| e.reset_walked}
    end

  end

  return nil
end

def check_answer(combined_cycle, k:)

  full_cycle = combined_cycle + combined_cycle[0..(k-1)]

  valid = true

  # puts "Checking answer"
  # @nodes.each{|n| puts n.inspect }

  all_nodes.each_with_index do |node,index|
    if !full_cycle.include?(node.data)
      valid = false
      break
    end

  end

  if valid && all_nodes.count != 0
  else
    puts "Invalid Answer"
  end

end



def find_contigs
  valid_nodes = $datastore.nodes.select{|n| !(n.degree == 1 && n.indegree == 1) && n.degree > 0}

  puts "#find_contigs - Found #{valid_nodes.count} valid nodes in"

  contigs = []

  valid_nodes.each do |node|

    edges = node.edges

    edges.each do |edge|

      current_node = edge.to_node
      current_path = [edge]

      while current_node.one_in_one_out

        # debugger if current_node.edges.count != 1

        next_edge = current_node.edges.first
        current_node = next_edge.to_node
        current_path << next_edge
      end

      contigs << current_path

    end
  end

  printed_contigs = contigs.map{|c| print_cycle(c)}.sort
end

def generate_contigs_from_reads(reads)

  reads = reads.split("\n").map(&:strip).reject{|n| n.blank? }

  # debugger if reads.first.nil?
  k = reads.first.length

  node_length = k - 1 # on debruijn graphs each node is k-1 in length

  reads.each_with_index do |pair,index|
    first_pair = pair[0...node_length]
    one = add_node(data: first_pair)

    second_pair = pair[1..(node_length+1)]
    two = add_node(data: second_pair)

    create_edge(from: one, to: two)

    # puts "generate_contigs_from_reads @ #{index}" if index % 200 == 0
  end

  puts "Created #{$datastore.edges.count} edges"

  contigs = find_contigs

  return contigs
end

def get_kmers_for_dna(dna,k)
  kmers = []

  i = 0
  while i < dna.length-k+1
    kmers << dna[i..(i+k-1)]
    i+=1
  end

  return kmers
end

def look_for_bubbles

  possible_bubble_starts = $datastore.nodes.select{|n| n.indegree < n.degree && n.indegree > 0}

  possible_bubble_starts_count = possible_bubble_starts.count

  puts "Found #{possible_bubble_starts_count} Bubbles"

  possible_bubble_starts.each_with_index do |node, index|

    edges_weight = node.edges.map(&:weight)
    highest_edge_weight = edges_weight.max

    puts "Found super linked node #{node.inspect}" if node.edges.count > 2

    node.edges.select{|e| e.weight != highest_edge_weight}.each do |current_edge|

      path_to_prune = [current_edge]

      current_node = current_edge.to_node

      while current_node.one_in_one_out
        next_edge = current_node.edges.first
        current_node = next_edge.to_node
        path_to_prune << next_edge
      end

      $datastore.remove_path(path_to_prune)

      puts "Removing bubble (#{index+1} of #{possible_bubble_starts_count}): #{print_cycle(path_to_prune)}"

    end


  end

end


# if !RbConfig.ruby.include?("truffleruby")
#   # require 'byebug'
# else
#   puts "Not including debugger"
#   define_method :"debugger" do
#   end
# end

# To not pollute the runs
def puts(o, override: false)
  if $debug_print || override
    super(o)
  end
end

class AssemblerRun

  attr_accessor :options

  def initialize(opts={})
    @options = opts
  end

  def run
    $debug_print = options[:print]

    $datastore = Datastore.new
    @eulerian_cycle = []
    @find_new_partial_node = lambda { all_nodes.select{|n| n.walkable? }.sample}
    @total_edges_count = lambda { all_nodes.map{|n| n.edges_count}.sum }


    $start_time = Time.now
    puts "Starting new run at #{$start_time}, with options: #{options}"
    @k = options[:k]
    @filename = options[:filename]

    genes = load_genes_from_fasta(@filename)

    paired_reads = []
    $partial_paths = []

    genes.each do |gene|
      paired_reads << get_kmers_for_dna(gene[:data],@k)
    end

    kmers = paired_reads.flatten


    kmers_with_counts_array = kmers.group_by{|e| e}.map{|k, v| [k, v.length]}.sort{|x,y| x[1] <=> y[1]}.reverse


    if options[:trash_kmers]

      kmers_lookup_hash = {}

      kmers_to_trash = kmers_with_counts_array.select{|k| k[1] <= 2}.map{|k| k[0]}.each{|k| kmers_lookup_hash[k] = true}

      kmers = kmers.select{|k| kmers_lookup_hash[k].nil? }

      puts "Trashing kmers with values < 3"
    end

    puts "Found #{kmers.uniq.count} unique kmers"

    contigs = generate_contigs_from_reads(kmers.join("\n"))


    look_for_bubbles

    final_contigs = find_contigs

    final_contigs.each_with_index do |contig, index|
       puts ">#{index} #{contig.length}\n"
       puts contig
    end

    if options[:output_filename] != nil
      output_filename = options[:output_filename]

      begin
        file = File.open(output_filename, "w")

        final_contigs.each_with_index do |contig, index|
           file.write ">#{index} #{contig.length}\n"
           file.write "#{contig}\n"
        end
        file.write "\n\n"
      rescue IOError => e
        puts e
        #some error occur, dir not writable etc.
      ensure
        file.close unless file.nil?
      end

      get_fasta_stats(output_filename, "#{output_filename}.stats", options: options)

      puts output_filename
    end

    puts "Time Ellapsed: #{Time.now - $start_time}"

  end

end

options = {
  k: 15,
  trash_kmers: false,
  print: false
}

OptionParser.new do |opts|
  opts.banner = "Usage: main.rb [options]"

  # opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
  #   options[:verbose] = v
  # end

  opts.on("-f", "--filename=FILENAME") do |f|
    options[:filename] = f
  end

  opts.on("-k", "--kvalue=KVALUE") do |v|
    options[:k] = v.to_i
  end

  opts.on("--trash", "Trash low kmers") do |v|
    options[:trash_kmers] = true
  end

  opts.on("-o","--outputfilename=OUTPUTFILENAME", "Output filename") do |v|
    options[:output_filename] = v
  end

  opts.on("--print", "Print statements in progress") do |f|
    options[:print] = true
  end

end.parse!

new_assembler_run = AssemblerRun.new(options)

n = 20
Benchmark.bm do |x|
  n.times do |i|
    x.report{ new_assembler_run.run }
  end
end
