# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

require "rubocop/rake_task"

RuboCop::RakeTask.new

task default: %i[spec rubocop readme]

desc "generate sample files"
task :generate_sample_files do
  require "xaba"

  name = "test"
  data = "A" * 1024
  compressed_data = LZ4.block_compress(data)

  c = XABA::Container.new
  c.file_header = XABA::FileHeader.new magic: "XABA", version: 1, local_entry_count: 1, global_entry_count: 1,
                                       store_id: 0
  c.descriptors = [
    XABA::AssemblyDescriptor.new(
      data_offset: XABA::FileHeader::SIZE + XABA::AssemblyDescriptor::SIZE + (XABA::HashEntry::SIZE * 2),
      data_size: compressed_data.size + XABA::DataEntry::SIZE,
      debug_data_offset: 0,
      debug_data_size: 0,
      config_data_offset: 0,
      config_data_size: 0
    )
  ]
  c.hash32_entries = [
    XABA::HashEntry.new(
      hash: XXhash.xxh32(name),
      mapping_index: 0,
      local_store_index: 0,
      store_id: 0
    )
  ]
  c.hash64_entries = [
    XABA::HashEntry.new(
      hash: XXhash.xxh64(name),
      mapping_index: 0,
      local_store_index: 0,
      store_id: 0
    )
  ]
  de = XABA::DataEntry.new(
    original_size: data.size,
    index: 0,
    magic: "XALZ"
  )
  de.data = compressed_data
  c.data_entries = [de]
  File.open("spec/samples/1.blob", "wb") do |f|
    c.write(f)
  end

  m = XABA::Manifest.new
  m.assemblies = [
    XABA::Manifest::AssemblyInfo.new(
      "0x%x" % XXhash.xxh32(name),
      "0x%x" % XXhash.xxh64(name),
      0,
      0,
      name
    )
  ]
  File.open(fname1 = "spec/samples/1.manifest", "wb") do |f|
    m.write(f)
  end

  ### 2nd file

  name = "test2"
  data = name
  compressed_data = LZ4.block_compress(data)

  m.assemblies << XABA::Manifest::AssemblyInfo.new(
    "0x%x" % XXhash.xxh32(name),
    "0x%x" % XXhash.xxh64(name),
    0,
    1,
    name
  )

  File.open("spec/samples/2.manifest", "wb") do |f|
    m.write(f)
  end

  c.file_header.local_entry_count += 1
  c.file_header.global_entry_count += 1

  c.descriptors << XABA::AssemblyDescriptor.new(
    data_offset: File.size(fname1) + XABA::AssemblyDescriptor::SIZE + (XABA::HashEntry::SIZE * 2),
    data_size: compressed_data.size + XABA::DataEntry::SIZE,
    debug_data_offset: 0,
    debug_data_size: 0,
    config_data_offset: 0,
    config_data_size: 0
  )
  c.hash32_entries << XABA::HashEntry.new(
    hash: XXhash.xxh32(name),
    mapping_index: 0,
    local_store_index: 0,
    store_id: 0
  )

  c.hash64_entries << XABA::HashEntry.new(
    hash: XXhash.xxh64(name),
    mapping_index: 0,
    local_store_index: 0,
    store_id: 0
  )
  de = XABA::DataEntry.new(
    original_size: data.size,
    index: 0,
    magic: "XALZ"
  )
  de.data = compressed_data
  c.data_entries << de
  File.open("spec/samples/2.blob", "wb") do |f|
    c.write(f)
  end
end

desc "build readme"
task :readme do
  require "erb"
  tpl = File.read("README.md.tpl").gsub(/^%\s+(.+)/) do |x|
    x.sub!(/^%/, "")
    "<%= run(\"#{x}\") %>"
  end
  result = ERB.new(tpl, trim_mode: "%>").result
  File.write("README.md", result)
end

def run(cmd)
  cmd.strip!
  puts "[.] #{cmd}"
  r = "    # #{cmd}\n\n"
  cmd.sub!(/^xaba/, "./exe/xaba")
  lines = `#{cmd}`.sub(/\A\n+/m, "").sub(/\s+\Z/, "").split("\n")
  lines = lines[0, 25] + ["..."] if lines.size > 50
  r << lines.map { |x| "    #{x}" }.join("\n")
  r << "\n"
end
