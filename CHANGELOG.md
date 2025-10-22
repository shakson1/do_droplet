# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-10-22

### Changed
- **BREAKING**: Removed provider block from module (users must now configure provider in consuming code)
- **BREAKING**: Removed `do_token` variable (API token should be configured in provider block)
- Removed `timestamp()` from tags for better state stability
- Improved module structure following Terraform best practices
- Enhanced documentation with better examples

### Added
- `.gitignore` for better repository management
- `.editorconfig` for consistent coding style
- `Makefile` for common operations
- `.terraform-docs.yml` for automated documentation
- `.pre-commit-config.yaml` for automated code quality checks
- `CONTRIBUTING.md` with contribution guidelines
- `LICENSE` file
- Multiple example configurations (minimal, complete, with-load-balancer)
- Improved test structure with proper fixtures

### Fixed
- Unused data sources removed for better performance
- Improved variable validation
- Better resource naming conventions

## [1.0.0] - 2024-XX-XX

### Added
- Initial release with basic droplet, volume, and firewall support
- Load balancer support
- VPC support
- SSH key management
- Floating IP support
- User data templating

