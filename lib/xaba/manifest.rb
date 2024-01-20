# frozen_string_literal: true

module XABA
  class Manifest
    attr_accessor :assemblies

    class AssemblyInfo
      attr_accessor :hash32, :hash64, :blob_id, :blob_idx, :name

      def initialize(hash32, hash64, blob_id, blob_idx, name)
        @hash32 = hash32.to_i(16)
        @hash64 = hash64.to_i(16)
        @blob_id = blob_id.to_i
        @blob_idx = blob_idx.to_i
        @name = name
        raise unless valid?
      end

      def inspect
        format("<AssemblyInfo hash32=%08x hash64=%016x blob_id=%d blob_idx=%3d name=%s>", hash32, hash64, blob_id,
               blob_idx, name.inspect)
      end

      def valid?
        XXhash.xxh32(name) == hash32 && XXhash.xxh64(name) == hash64
      end
    end

    HEADER = "Hash 32     Hash 64             Blob ID  Blob idx  Name"

    def self.read(fname = "assemblies.manifest")
      lines = File.readlines(fname).map(&:chomp).map(&:split)
      header = lines.shift
      raise "invalid header: #{header.inspect}" if header != HEADER.split

      assemblies = lines.map do |line|
        AssemblyInfo.new(*line)
      end

      new assemblies
    end

    def write(f)
      data = [HEADER] + @assemblies.map do |a|
                          format("0x%08x  0x%016x  %03d      %04d      %s",
                                 a.hash32, a.hash64, a.blob_id, a.blob_idx, a.name)
                        end
      f.write("#{data.join("\n")}\n")
    end

    def initialize(assemblies = nil)
      @assemblies = assemblies
    end

    def each(&block)
      @assemblies.each(&block)
    end
  end
end
