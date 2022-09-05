.install.deps: Gemfile Gemfile.lock
	bundle install
	touch $@

.PHONY: generate
generate: .install.deps
	bundle exec ruby lib/generator.rb $(CONFIG)
