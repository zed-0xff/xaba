# frozen_string_literal: true

require_relative "lib/xaba/version"

Gem::Specification.new do |spec|
  spec.name = "xaba"
  spec.version = XABA::VERSION
  spec.authors = ["Andrey \"Zed\" Zaikin"]
  spec.email = ["zed.0xff@gmail.com"]

  spec.summary = "(un)packer for Xamarin assemblies.blob"
  spec.description = spec.summary
  spec.homepage = "https://github.com/zed-0xff/xaba"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "extlz4", "~> 0.3.4"
  spec.add_dependency "iostruct", "~> 0.0.5"
  spec.add_dependency "xxhash", "~> 0.5.0"

  spec.metadata["rubygems_mfa_required"] = "true"
end
