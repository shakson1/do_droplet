# Contributing to DigitalOcean Droplet Terraform Module

Thank you for your interest in contributing to this project! We welcome contributions from the community.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Submitting Changes](#submitting-changes)
- [Coding Standards](#coding-standards)

## Code of Conduct

This project adheres to a code of conduct that we expect all contributors to follow. Please be respectful and professional in all interactions.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/digitalocean-droplet.git`
3. Create a feature branch: `git checkout -b feature/my-new-feature`
4. Make your changes
5. Test your changes
6. Submit a pull request

## Development Setup

### Prerequisites

- [Terraform](https://www.terraform.io/downloads.html) >= 1.5.0
- [Go](https://golang.org/dl/) >= 1.21 (for tests)
- [terraform-docs](https://terraform-docs.io/) (for documentation)
- [tflint](https://github.com/terraform-linters/tflint) (for linting)
- [checkov](https://www.checkov.io/) (for security scanning)
- [pre-commit](https://pre-commit.com/) (optional, for automated checks)

### Installation

```bash
# Install pre-commit hooks (optional but recommended)
pre-commit install

# Initialize Terraform
make init

# Validate configuration
make validate
```

## Making Changes

### Branch Naming

Use descriptive branch names:
- `feature/add-new-resource` - For new features
- `fix/issue-123` - For bug fixes
- `docs/update-readme` - For documentation updates
- `refactor/improve-locals` - For code refactoring

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
<type>(<scope>): <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat(droplet): add support for reserved IPs

Add support for DigitalOcean reserved IPs with automatic
assignment to droplets.

Closes #123
```

## Testing

### Running Tests

```bash
# Format code
make format

# Validate Terraform
make validate

# Run linter
make lint

# Run security checks
make security

# Run all tests
make test

# Test examples
make test-examples
```

### Writing Tests

- Add unit tests for new features
- Add integration tests for complex features
- Update existing tests if behavior changes
- Ensure all tests pass before submitting PR

## Submitting Changes

### Pull Request Process

1. Update documentation (README.md, CHANGELOG.md)
2. Add/update tests for your changes
3. Ensure all tests pass
4. Update examples if needed
5. Run `make format` and `make lint`
6. Submit PR with clear description

### Pull Request Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Unit tests added/updated
- [ ] Integration tests added/updated
- [ ] All tests passing
- [ ] Examples tested

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] CHANGELOG.md updated
- [ ] No breaking changes (or clearly documented)
```

## Coding Standards

### Terraform

- Use 2 spaces for indentation
- Use meaningful resource and variable names
- Add descriptions to all variables and outputs
- Include validation for variables when applicable
- Use `locals` for computed values
- Comment complex logic
- Follow HashiCorp's [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)

### Variables

```hcl
variable "example" {
  description = "Clear description of the variable"
  type        = string
  default     = "default-value"

  validation {
    condition     = length(var.example) > 0
    error_message = "Variable must not be empty."
  }
}
```

### Resources

```hcl
resource "digitalocean_droplet" "this" {
  name   = "${local.name_prefix}${var.name}"
  region = var.region
  size   = var.size
  image  = var.image

  # Use lifecycle blocks when appropriate
  lifecycle {
    prevent_destroy = var.prevent_destroy
  }
}
```

### Outputs

```hcl
output "droplet_id" {
  description = "The ID of the created droplet"
  value       = digitalocean_droplet.this.id
}
```

## Documentation

### Generating Documentation

```bash
# Generate documentation
make docs
```

### Documentation Standards

- Keep README.md up to date
- Add examples for new features
- Document breaking changes in CHANGELOG.md
- Use clear and concise language
- Include code examples where appropriate

## Questions?

If you have questions or need help, please:
1. Check existing issues and discussions
2. Create a new issue with your question
3. Reach out to maintainers

Thank you for contributing! 🎉

