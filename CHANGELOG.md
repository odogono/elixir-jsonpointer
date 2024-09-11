# Changelog

Written with guidance from [Keep a CHANGELOG](http://keepachangelog.com/).
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]


## v3.1.0 (2024-09-11)
### Changed
- updated package dependencies
- error handling for get on invalid containers
- error message format changed to be more consistent

## v3.0.1 (2019-07-31)
### Fixed
- crash when retrieving a path which contains a null value


## v3.0.0 (2019-02-27)
### Added
- add/add! - adds values indicated by pointers
- options can be passed to operations. only option so far is :strict which affects set/add behaviour
- added JSONPointer.test - checks whether the given pointer has the given value

### Changed
- has changed to has? as it returns a single boolean
- stricter parsing of integer indexes
- increased terseness of error messages
- remove now actually reduces the list size, rather than replace with nil

### Fixed
- corrected parsing of /~01


## v2.5.0 (2019-02-22)
### Added
- support for special array rules - /01 is not evaluated to an integer
- the /- pointer when used with set either appends the value to the end of a list, or
creates a new list with the value


## v2.4.0 (2019-04-01)
### Fixed
- pointers are no longer uri decoded, so the rfc example of "/c%d" now works correctly


## v2.3.0 (2018-05-09)
### Changed
- JSONPointer.apply changed to JSONPointer.transform

## v2.2.0 (2018-04-12)
### Added
- hydrate and dehydrate functions added
- apply added - a utility to transform a source container

### Removed
- extract - renamed to dehydrate


## v2.1.0 (2018-04-12)
### Added
- set!, extract!, merge!


## v2.0.0 (2018-01-19)
### Changed
- passing a string to get/set will raise an argument error
- new elixir formatter applied to code
- code refactored to use defguard - which means this package is > 1.6 only

## v1.3.0 (2017-12-21)
### Fixed
- deprecation warning for String.ltrim
- Unsafe variable warnings

## v1.2.0 (2016-04-11)
### Added
- parse will take a list of strings
- JSONPointer.extract returns a list of paths that make up an object
- JSONPointer.merge combines dst into src

## v1.1.0 (2016-03-04)
### Added
- pointers can be passed as lists as well as strings


## v1.0.0 (2016-03-03)
* Initial Release
