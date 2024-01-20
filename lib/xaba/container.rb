# frozen_string_literal: true

module XABA
  class Container
    attr_accessor :file_header, :descriptors, :hash32_entries, :hash64_entries, :data_entries

    def read(f)
      return if f.nil?

      @file_header = FileHeader.read(f)
      @descriptors = @file_header.local_entry_count.times.map { AssemblyDescriptor.read(f) }
      @hash32_entries = @file_header.local_entry_count.times.map { HashEntry.read(f) }
      @hash64_entries = @file_header.local_entry_count.times.map { HashEntry.read(f) }

      @data_entries = @descriptors.map do |d|
        DataEntry.read(f).tap do |de|
          de.data = f.read(d.data_size - DataEntry::SIZE)
        end
      end
      self
    end

    def replace!(idx, newdata)
      compressed_data = LZ4.block_compress(newdata)
      delta = compressed_data.bytesize - data_entries[idx].data.bytesize
      descriptors[idx].data_size += delta
      data_entries[idx].original_size = newdata.bytesize
      data_entries[idx].data = compressed_data

      descriptors[idx + 1..].each do |d|
        d.data_offset += delta
      end
    end

    def write(f)
      f.write @file_header.pack
      @descriptors.each do |d|
        f.write d.pack
      end
      @hash32_entries.each do |e|
        f.write e.pack
      end
      @hash64_entries.each do |e|
        f.write e.pack
      end
      @data_entries.each do |e|
        f.write e.pack
      end
    end

    def self.read(fname)
      File.open(fname, "rb") do |f|
        new.read(f)
      end
    end
  end

  class FileHeader < IOStruct.new("a4LLLL", :magic, :version, :local_entry_count, :global_entry_count, :store_id)
    def inspect
      super.sub(/^#<struct /, "<")
    end

    def self.read(f)
      r = super
      raise "invalid magic: #{r.magic}" if r.magic != "XABA"

      r
    end
  end

  class AssemblyDescriptor < IOStruct.new(
    "llllll",
    :data_offset, :data_size,
    :debug_data_offset, :debug_data_size,
    :config_data_offset, :config_data_size
  )
    def inspect
      super.sub(/^#<struct /, "<")
    end
  end

  # hashes of assembly _name_
  # same entry for hash32 and hash64
  class HashEntry < IOStruct.new("QLLL", :hash, :mapping_index, :local_store_index, :store_id)
    def inspect
      format("<HashEntry hash=%016x mapping_index=%3d local_store_index=%3d store_id=%d>", hash, mapping_index,
             local_store_index, store_id)
    end
  end

  class DataEntry < IOStruct.new("a4LL", :magic, :index, :original_size)
    attr_accessor :data

    def inspect
      super.sub(/^#<struct /, "<")
    end

    def pack
      super + data
    end

    def self.read(f)
      r = super
      raise "invalid magic: #{r.magic}" if r.magic != "XALZ"

      r
    end
  end
end
