## Changelog
Written with guidance from [Keep a CHANGELOG](http://keepachangelog.com/).
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## v2.4.0
### Fixed
- pointers are no longer uri decoded, so the rfc example of "/c%d" now works correctly


## v2.3.0
### Changed
- JSONPointer.apply changed to JSONPointer.transform

## v2.2.0
### Added
- hydrate and dehydrate functions added
- apply added - a utility to transform a source container

### Removed
- extract - renamed to dehydrate


## v2.1.0
### Added
- set!, extract!, merge!


## v2.0.0
### Changed
- passing a string to get/set will raise an argument error
- new elixir formatter applied to code
- code refactored to use defguard - which means this package is > 1.6 only

## v1.3.0
### Fixed
- deprecation warning for String.ltrim
- Unsafe variable warnings

## v1.2.0
### Added
- parse will take a list of strings
- JSONPointer.extract returns a list of paths that make up an object 
- JSONPointer.merge combines dst into src

## v1.1.0
## Added
- pointers can be passed as lists as well as strings


## v1.0.0
* Initial Release
