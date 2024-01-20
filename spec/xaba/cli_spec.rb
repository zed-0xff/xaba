# frozen_string_literal: true

require "fileutils"

RSpec.describe "xaba" do
  let(:tmpdir) { "tmp" }
  let(:command) do
    XABA::CLI.new.run(RSpec.current_example.example_group.description.split)
  rescue SystemExit
    raise "exit"
  end

  before do
    FileUtils.mkdir_p(tmpdir)
    FileUtils.rm_f("#{tmpdir}/test")
    FileUtils.rm_f("#{tmpdir}/test2")
    FileUtils.rm_f("#{tmpdir}/test2.dll")
    FileUtils.rm_f("#{tmpdir}/test2.dll")
    FileUtils.rm_f("#{tmpdir}/newblob")
  end

  context "--version" do
    it "outputs the version" do
      expect { command }.to output("#{XABA::VERSION}\n").to_stdout
    end
  end

  %w[--help -h].each do |arg|
    context arg do
      it "outputs the help" do
        expect { command }.to output(/Usage: xaba \[options\] \[files\]/).to_stdout
      end
    end
  end

  manifest_fname = "spec/samples/2.manifest"
  blob_fname = "spec/samples/2.blob"

  %w[--list -l].each do |arg|
    [
      "--manifest #{manifest_fname}", "-m #{manifest_fname}",
      "--blob #{blob_fname}", "-b #{blob_fname}"
    ].each do |arg2|
      context "#{arg} #{arg2}" do
        it "lists the assemblies in the blob" do
          expect { command }.to output(
            " idx name\n   " \
            "0 test\n   " \
            "1 test2\n"
          ).to_stdout
        end
      end
    end
  end

  %w[test test.dll].each do |fname|
    context "-o tmp -m #{manifest_fname} -b #{blob_fname} --unpack #{fname}" do
      it "unpacks only specified file" do
        command
        expect(Dir["#{tmpdir}/*"]).to eq([
                                           "#{tmpdir}/test.dll"
                                         ])
        expect(File.read("#{tmpdir}/test.dll")).to eq("A" * 1024)
      end
    end
  end

  %w[--unpack -u].each do |arg|
    context "-o tmp -m #{manifest_fname} #{arg}" do
      it "unpacks all files" do
        command
        expect(Dir["#{tmpdir}/*"]).to eq([
                                           "#{tmpdir}/test.dll",
                                           "#{tmpdir}/test2.dll"
                                         ])
      end

      it "unpacks files correctly" do
        command
        expect(File.read("#{tmpdir}/test.dll")).to eq("A" * 1024)
        expect(File.read("#{tmpdir}/test2.dll")).to eq("test2")
      end
    end
  end

  %w[--replace -r].each do |arg|
    "tmp/test tmp/test.dll".split.each do |fname|
      context "-o tmp/newblob -m #{manifest_fname} #{arg} #{fname}" do
        it "replaces file correctly" do
          replacement_text = "this is replacement\n" * 3
          File.write(fname, replacement_text)
          command
          FileUtils.rm(fname)
          XABA::CLI.new.run("--unpack -o tmp -m #{manifest_fname} -b tmp/newblob".split)
          expect(File.read("#{tmpdir}/test.dll")).to eq(replacement_text)
          expect(File.read("#{tmpdir}/test2.dll")).to eq("test2")
        end
      end
    end
  end
end
