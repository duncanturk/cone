PUBSPECLOCK=pubspec.lock
TYPESGDART=lib/src/types.g.dart

$(PUBSPECLOCK):
	flutter pub get

$(TYPESGDART): $(PUBSPECLOCK)
	dart run build_runner build

build: $(TYPESGDART)

watch:
	dart run build_runner watch

analyze:
	ls lib/**/*.dart test/*.dart | entr -s 'dartanalyzer .'

docs:
	ls lib/**/*.dart | entr dartdoc

.PHONY: test

test:
	ls lib/**/*.dart test/*.dart | entr -s 'pub run test'

parse_test:
	ls lib/**/*.dart test/*.dart | entr -s 'pub run test test/parse_test.dart'

test_coverage:
	ls lib/**/*.dart test/*.dart | entr -s 'pub run test_coverage && genhtml -o coverage coverage/lcov.info'
