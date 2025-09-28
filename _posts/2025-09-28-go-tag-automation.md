---
title: Automating Go Package Version Management
date: 2025-09-28
categories: [Software Development]
tags: [Go, CLI, Git, Version Management, Open Source, Tooling]
author: gambitier
pin: false
---

Managing version tags across multiple Go repositories can be a tedious and error-prone task. After working with numerous Go projects, I found myself repeatedly performing the same manual steps: discovering packages, checking current tags, calculating new versions, and creating Git tags. This led me to build **Tag Manager** - a generic command-line utility that automates and streamlines the entire process.

## The Problem

When working with multiple Go repositories, I often encountered these challenges:

- **Manual Discovery**: Scanning through directories to find `go.mod` files
- **Inconsistent Tagging**: Different projects using different tag naming conventions
- **Repetitive Workflow**: Same steps for every package update
- **Error-Prone Process**: Manual tag creation and Git operations
- **No Configuration Memory**: Re-entering preferences for each package

## The Solution: Tag Manager

### 🔍 **Smart Package Discovery**
```bash
$ tag-manager list
┌───┬───────────────┬───────────────┐
│ # │   PACKAGE     │ LATEST TAG    │
├───┼───────────────┼───────────────┤
│ 1 │ storage-utils │ v0.0.2        │
│ 2 │ config        │ v1.2.3        │
│ 3 │ cache         │ cache/v2.0.1  │
└───┴───────────────┴───────────────┘
```

### 🏷️ **Flexible Tag Formats**
The tool supports various tag naming conventions:

- **Default**: `{package-name}/v{major}.{minor}.{patch}`
- **Simple**: `{version}` (e.g., `v1.2.3`)
- **Custom**: `{package-name}-v{major}.{minor}.{patch}`
- **Repository-specific**: Each package can have its own format

### ⚙️ **Persistent Configuration**
```yaml
packages:
  github.com/example/package:
    module_path: github.com/example/package
    tag_format: '{version}'
    use_default: false
    last_updated: '2024-01-15T10:30:00Z'
defaults:
  tag_format: '{package-name}/v{major}.{minor}.{patch}'
```

### 🎯 **Interactive Workflow**
```bash
$ tag-manager update
# 1. Shows available packages
# 2. Guides through configuration setup
# 3. Calculates new version automatically
# 4. Confirms before creating tags
# 5. Creates and pushes Git tags
```

## Getting Started

Tag Manager is open source and available on GitHub with comprehensive documentation, installation instructions, and usage examples: [github.com/gambitier/tag-manager](https://github.com/gambitier/tag-manager)

## Benefits & Impact

### For Developers
- **Time Savings**: Reduces manual tag management from minutes to seconds
- **Consistency**: Enforces standardized tagging across projects
- **Error Reduction**: Automated validation prevents common mistakes
- **Flexibility**: Supports various organizational conventions

### For Teams
- **Standardization**: Unified approach to version management
- **Audit Trail**: Configuration tracking with timestamps
- **Onboarding**: New team members can quickly understand tagging conventions

## Open Source & Community

The project welcomes contributions and feedback. Visit the [GitHub repository](https://github.com/gambitier/tag-manager) to:
- Report issues and request features
- Contribute code improvements
- Help with documentation
- Share your use cases and feedback

## Conclusion

Building Tag Manager taught me valuable lessons about CLI tool design, Go package management, and user experience. The tool has already saved me hours of manual work and demonstrates how a focused solution can significantly improve developer productivity.

The key to building effective developer tools is understanding the pain points in daily workflows and creating solutions that are both powerful and easy to use. Whether you're managing a single Go project or dozens of repositories, Tag Manager provides the automation and consistency needed for effective version management.

---

*Have you built similar developer tools? I'd love to hear about your experiences and learn from your approaches to solving common development workflow challenges.*
