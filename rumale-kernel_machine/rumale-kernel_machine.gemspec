# frozen_string_literal: true

require_relative 'lib/rumale/kernel_machine/version'

Gem::Specification.new do |spec|
  spec.name = 'rumale-kernel_machine'
  spec.version = Rumale::KernelMachine::VERSION
  spec.authors = ['yoshoku']
  spec.email = ['yoshoku@outlook.com']

  spec.summary = 'Rumale::KernelMachine provides kernel method-based algorithms with Rumale interface.'
  spec.description = <<~MSG
    Rumale::KernelMachine provides kernel method-based algorithms,
    such as Kernel Support Vector Machine, Kernel Principal Componenet Analysis, and Kernel Ridge Regression,
    with Rumale interface.
  MSG
  spec.homepage = 'https://github.com/yoshoku/rumale'
  spec.license = 'BSD-3-Clause'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = "#{spec.homepage}/tree/main/rumale-kernel_machine"
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata['documentation_uri'] = 'https://yoshoku.github.io/rumale/doc/'
  spec.metadata['rubygems_mfa_required'] = 'true'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:(?:test|spec|features)/)}) }
                     .select { |f| f.match(/\.(?:rb|rbs|h|hpp|c|cpp|md|txt)$/) }
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  spec.add_dependency 'numo-narray', '>= 0.9.1'
  spec.add_dependency 'rumale-core', '~> 0.28.0'

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
end
