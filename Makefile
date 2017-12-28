help:
	@echo "Nothing really to make, but there are some available commands:"
	@echo " * test     : run some tests"
	@echo " * style    : style bash script"
	@echo " * feedback : create a GitHub issue"

feedback:
	@open https://github.com/alexanderwillner/things.sh/issues

test: check
	@echo "Running shell checks..."
	@shellcheck things.sh
	@echo "Running unit tests..."
	@bashcov shunit2 test/thingsTest.sh
	@cat coverage/index.html||true

style:
	@type shfmt >/dev/null 2>&1 || (echo "Run 'go get -u mvdan.cc/sh/cmd/shfmt' first." >&2 ; exit 1)
	@shfmt -i 2 -w things.sh

check:
	@type shellcheck >/dev/null 2>&1 || (echo "Run 'brew install shellcheck' first." >&2 ; exit 1)
	@type shunit2 >/dev/null 2>&1 || (echo "Run 'brew install shunit2' first." >&2 ; exit 1)
	@type bashcov >/dev/null 2>&1 || (echo "Run 'gem install bashcov' first." >&2 ; exit 1)
