prefix=/usr/local

all: help

help:
	@echo "Nothing really to make, but there are some available commands:"
	@echo " * install  : install application to $(prefix)"
	@echo " * clean    : cleanup"
	@echo " * test     : run some tests"
	@echo " * style    : style bash script"
	@echo " * feedback : create a GitHub issue"

install:
	@echo "Hint: consider to use 'brew install AlexanderWillner/tap/things.sh' instead"
	@install -m 0755 things.sh $(prefix)/bin

clean:
	@rm -rf coverage

feedback:
	@open https://github.com/alexanderwillner/things.sh/issues

test: check
	@echo "Running shell checks..."
	@shellcheck -x *.sh
	@shellcheck -x plugins/*.sh
	@echo "Running unit tests..."
	@bashcov -s shunit2 test/thingsTest.sh
	@file coverage/index.html||true

style:
	@type shfmt >/dev/null 2>&1 || (echo "Run 'brew install shfmt' first." >&2 ; exit 1)
	@shfmt -i 2 -w -s *.sh
	@shfmt -i 2 -w -s plugins/*.sh

check:
	@type shellcheck >/dev/null 2>&1 || (echo "Run 'brew install shellcheck' first." >&2 ; exit 1)
	@type shunit2 >/dev/null 2>&1 || (echo "Run 'brew install shunit2' first." >&2 ; exit 1)
	@type bashcov >/dev/null 2>&1 || (echo "Run 'gem install bashcov' first." >&2 ; exit 1)

.PHONY: install clean feedback test style check
