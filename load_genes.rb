require 'stringio'

def load_genes_from_fasta(filename)

  genes = []

  fasta_data_builder = StringIO.new

  last_header = ""

  lines  = File.readlines(filename)

  lines.each_with_index do |line,index|

    if line.scan(/>/).empty? && line != "\n"
      fasta_data_builder << line.chomp
    else
      if fasta_data_builder.string != ""
        genes << {header: last_header.chomp, data:fasta_data_builder.string}
        # puts "loaded #{last_header.chomp} #{index}"
        fasta_data_builder = StringIO.new
      end

      # debugger if (line == ">mystery_dna-2" || index == 94)

      # puts "HEADER: #{line}"
      last_header = line
    end

  end

  puts "Loaded #{genes.count} Genes"

  genes
end

def get_fasta_stats(gene_filename, output_filename, options:)
  genes = load_genes_from_fasta(gene_filename)

  k = options[:k]

  genes = genes.map{|g| {size: g[:data].length, data: g[:data], header: g[:header]}}

  average_contig_size = average_contig_size(genes)
  largest_contig_size = largest_contig_size(genes)
  computed_n50 = compute_n50(genes)


  begin
    file = File.open(output_filename, "w")

    file.write("Stats for #{options[:filename]}\n")
    file.write("Number of Contigs: #{genes.count}\n")
    file.write("Average Contig Size: #{average_contig_size}\n")
    file.write("Largest Contig Size: #{largest_contig_size}\n")
    file.write("N50: #{computed_n50}\n")
    file.write("K: #{k}\n")

    # final_contigs.each_with_index do |contig, index|
    #    file.write ">#{index} #{contig.length}\n"
    #    file.write "#{contig}\n"
    # end
  rescue IOError => e
    #some error occur, dir not writable etc.
  ensure
    file.close unless file.nil?
  end

end

def compute_n50(genes)
  sizes = genes.map{|g| g[:size]}.sort

  sum = sizes.sum
  half_of_sum = sum/2

  current_size = half_of_sum
  sizes.each do |size|
    current_size -= size

    if current_size < 0
      return size
    end
  end
end

def average_contig_size(genes)
  genes.map{|g| g[:size]}.sum / genes.count
end

def largest_contig_size(genes)
  genes.map{|g| g[:size]}.max
end

