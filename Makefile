help:
	@echo "Nothing really to make, but there are some available commands:"
	@echo " * test     : run some tests"
	@echo " * feedback : create a GitHub issue"

feedback:
	open https://github.com/alexanderwillner/things.sh/issues

test: check
	@echo "Running shell checks..."
	@shellcheck things.sh
	@echo "Running unit tests..."
	@shunit2 test/thingsTest.sh

check:
	@type shellcheck >/dev/null 2>&1 || (echo "Run 'brew install shellcheck' first." >&2 ; exit 1)
	@type shunit2 >/dev/null 2>&1 || (echo "Run 'brew install shunit2' first." >&2 ; exit 1)
