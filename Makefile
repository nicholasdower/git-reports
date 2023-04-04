.PHONY: install
install:
	bundle install
	touch $@

.PHONY: generate
generate: install
	bundle exec ruby lib/generator.rb $(CONFIG)
