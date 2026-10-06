require_relative "lib/keystone_ui/preferences/version"

Gem::Specification.new do |spec|
  spec.name = "keystone_ui-preferences"
  spec.version = KeystoneUi::Preferences::VERSION
  spec.authors = [ "Tyler Schneider" ]
  spec.email = [ "tylercschneider@gmail.com" ]
  spec.homepage = "https://github.com/DYB-Development/keystone_ui-preferences"
  spec.summary = "Per-user saved choices for Keystone UI components."
  spec.description = "A companion engine for keystone_ui that saves each person's choices for a component, such as a data table's hidden columns, and supplies them back to keystone_ui."
  spec.license = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["documentation_uri"] = "#{spec.homepage}#readme"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.required_ruby_version = ">= 3.1.0"

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]
  end

  spec.add_dependency "keystone_ui", ">= 0.33.1"
  spec.add_dependency "railties", ">= 7.0"
  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activesupport", ">= 7.0"
end
