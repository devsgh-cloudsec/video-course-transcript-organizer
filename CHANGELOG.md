# Changelog

All notable changes to the Video Course Transcript Organizer will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-07-27

### Added
- Initial release of Video Course Transcript Organizer
- Support for `.vtt` and `.srt` subtitle file processing
- Automatic cleaning of timestamps, metadata, and sequence numbers
- Sequential folder-based organization maintaining course structure
- Combined searchable transcript generation (`00-COMBINED-ALL.txt`)
- Progress tracking with colored console output
- Comprehensive error handling and detailed statistics
- UTF-8 encoding support for special characters and emojis
- Safe filename sanitization for cross-platform compatibility
- Optional path parameter for flexible usage
- Automatic results folder opening after processing

### Features
- Smart content filtering (removes WEBVTT headers, sound effects, HTML tags)
- Maintains proper sequential order (01, 02, 03... not alphabetical)
- Section headers in combined file for easy navigation
- Individual clean transcript files for focused study
- Detailed processing statistics and troubleshooting guidance
