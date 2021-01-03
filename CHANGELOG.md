# Changelog

## [1.0.0-nullsafety.0] 03.01.21

* Complete refactor
* Deprecated `encodeBlurHash` and `decodeBlurHash`.
  Use `BlurHash.encode` and `BlurHash.decode` instead.
* Initial nullsafe version.
  Currently only unsound nullsafety supported, because the dependency `image` is not
  migrated yet.

## [0.2.3] 22.02.20

* Make the pub.dev analysis tool happy
* Formatting

## [0.2.2] 22.02.20

* Fix minor style issues
* Make the pub.dev analysis tool happy by providing a longer description

## [0.2.1] 22.02.20

* Change import name as suggested by pub publish tool

## [0.2.0] 22.02.20

* Add support for encoding blurhashes
* Decoder now returns raw pixels in RGBA32

## [0.1.0] 21.02.20

* First release
