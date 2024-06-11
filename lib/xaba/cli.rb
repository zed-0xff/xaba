# frozen_string_literal: true

require "optparse"
require "fileutils"

module XABA
  class CLI
    def initialize
      @options = { verbosity: 0 }
    end

    def parse_args(args)
      OptionParser.new do |opts|
        opts.banner = "Usage: xaba [options] [files]"

        opts.separator "Commands:"

        opts.on("-l", "--list", "List assemblies in the blob") do
          @options[:command] = :list
        end

        opts.on("-u", "--unpack", "Unpack all or specified file(s)") do |_file|
          @options[:command] = :unpack
        end

        opts.on("-r", "--replace", "Replace file(s) in the blob") do |_file|
          @options[:command] = :replace
        end

        opts.separator ""
        opts.separator "Options:"

        opts.on("-m", "--manifest PATH", "Pathname of the input assemblies.manifest file") do |path|
          @options[:manifest] = path
        end

        opts.on("-b", "--blob PATH", "[and/or] pathname of the input assemblies.blob file") do |path|
          @options[:blob] = path
        end

        opts.separator ""

        opts.on("-o", "--output PATH",
                "Pathname for the output assemblies.blob file when replacing",
                "Pathname for the output dir when unpacking") do |path|
          @options[:output] = path
        end

        opts.on("-v", "--verbose", "Increase verbosity") do
          @options[:verbosity] += 1
        end

        opts.on("--version", "Prints the version") do
          @options[:command] = :version
        end

        opts.on("-h", "--help", "Prints this help") do
          # intentonally left blank
        end
      end.tap { |o| o.parse!(args) }
    end

    def guess_missing_file_paths
      if @options[:blob] && @options[:manifest]
        # OK
      elsif @options[:blob] && !@options[:manifest]
        @options[:manifest] = "#{@options[:blob].sub(/\.blob$/, "")}.manifest"

      elsif @options[:manifest] && !@options[:blob]
        @options[:blob] = "#{@options[:manifest].sub(/\.manifest$/, "")}.blob"
      else
        abort "[!] The --blob or --manifest option is required"
      end
    end

    def read_manifest
      Manifest.read(@options[:manifest])
    end

    def read_blob
      Container.read(@options[:blob])
    end

    def read_all
      guess_missing_file_paths
      @manifest = read_manifest
      @blob = read_blob
    end

    ### run

    def run(args = ARGV)
      option_parser = parse_args(args)
      @args = args
      unless @options[:command]
        puts option_parser
        return
      end

      send @options[:command]
    end

    ### commands

    def version
      puts XABA::VERSION
    end

    def list
      read_all

      case @options[:verbosity]
      when 2..Float::INFINITY
        puts "[.] manifest:"
        @manifest.assemblies.each_with_index do |e, i|
          printf "%5d: %s\n", i, e.inspect
        end

        puts
        puts "[.] blob file header:"
        printf "    %s\n", @blob.file_header.inspect

        puts
        puts "[.] assembly descriptors:"
        @blob.descriptors.each_with_index do |e, i|
          printf "%5d: %s\n", i, e.inspect
        end

        puts
        puts "[.] hash32 entries:"
        @blob.hash32_entries.each_with_index do |e, i|
          printf "%5d: %s\n", i, e.inspect
        end

        puts
        puts "[.] hash64 entries:"
        @blob.hash64_entries.each_with_index do |e, i|
          printf "%5d: %s\n", i, e.inspect
        end

        puts
        puts "[.] data entries:"
        @blob.data_entries.each_with_index do |e, i|
          printf "%5d: %s\n", i, e.inspect
        end
      when 1
        printf "%8s %8s %8s %8s %8s %8s %s\n", "idx", "doffset", "compsz", "origsz", "configsz", "dbgsz", "name"
        @manifest.assemblies.each_with_index do |a, i|
          data_offset = @blob.descriptors[i].data_offset
          compsz = @blob.descriptors[i].data_size
          origsz = @blob.data_entries[i].original_size
          configsz = @blob.descriptors[i].config_data_size
          dbgsz = @blob.descriptors[i].debug_data_size
          printf "%8d %8x %8d %8d %8d %8d %s\n", a.blob_idx, data_offset, compsz, origsz, configsz, dbgsz, a.name
        end
      else
        # minimal verbosity
        printf "%4s %s\n", "idx", "name"
        @manifest.assemblies.each do |a|
          printf "%4d %s\n", a.blob_idx, a.name
        end
      end
    end

    def unpack
      abort "[!] The --output option is required for the replace command" unless @options[:output]
      read_all

      FileUtils.mkdir_p(@options[:output])

      @blob.data_entries.each_with_index do |de, idx|
        name = @manifest.assemblies[idx].name
        next if @args.any? && !@args.include?(name) && !@args.include?("#{name}.dll")

        decompressed = LZ4.block_decode(de.data)
        dll_fname = File.join(@options[:output], "#{name}.dll")
        File.binwrite dll_fname, decompressed

        File.binwrite("#{dll_fname}.config", de.config) if de.config
      end
    end

    def replace
      abort "[!] The --output option is required for the replace command" unless @options[:output]
      abort "[!] No files specified for the replace command" if @args.empty?
      read_all

      # convert args to hash
      h = {}
      @args.each do |arg|
        if File.exist?(arg)
          h[File.basename(arg, ".dll")] = File.binread(arg)
        else
          abort "[!] cannot find #{arg}"
        end
      end

      @blob.data_entries.each_with_index do |_de, idx|
        name = @manifest.assemblies[idx].name
        @blob.replace!(idx, h[name]) if h[name]
      end

      File.open(@options[:output], "wb") do |f|
        @blob.write(f)
      end
    end
  end
end
