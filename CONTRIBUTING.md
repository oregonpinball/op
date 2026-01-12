# Contributing to OP

## Development

### Prerequisites

- See README.md for technical requirements for Erlang and Elixir

### Common commands

```bash
# Start the Phoenix server
mix phx.server

# Run tests
mix test

# Run tests for a specific file
mix test test/path/to/test_file.exs

# Run previously failed tests
mix test --failed

# Get dependencies
mix deps.get

# Setup database (create, migrate, and seed)
mix ecto.setup

# Create database
mix ecto.create

# Run migrations
mix ecto.migrate

# Rollback migrations
mix ecto.rollback

# Reset database (drop, create, migrate, and seed)
mix ecto.reset
```

### Code style

This project uses `mix format` for code formatting. You can format your code manually with:

```bash
mix format
```

### IDE

This project works best with IDEs that support **ElixirLS** (Elixir Language Server) for features like autocomplete, go-to-definition, inline documentation, and code formatting.

**Recommended IDE:**

- **Visual Studio Code** - Most popular option with ElixirLS support
  - Extension: [ElixirLS](https://marketplace.visualstudio.com/items?itemName=JakeBecker.elixir-ls) by Jake Becker
  - Extension: [Phoenix Framework](https://marketplace.visualstudio.com/items?itemName=phoenixframework.phoenix) for additional Phoenix-specific features


#### Format on Save in VS Code

To automatically format Elixir files on save in Visual Studio Code:

1. **Install the Elixir extension:**
   - Open VS Code Extensions (Ctrl+Shift+X or Cmd+Shift+X)
   - Search for "ElixirLS: Elixir support and debugger" by Jake Becker
   - Click Install

2. **Configure format on save:**
   - Open VS Code Settings (File > Preferences > Settings or Code > Settings > Settings)
   - Search for "format on save"
   - Enable "Editor: Format On Save"

3. **Configure Elixir as the default formatter:**
   - In Settings, search for "default formatter"
   - Or add to your `.vscode/settings.json`:
   ```json
   {
     "editor.formatOnSave": true,
     "[elixir]": {
       "editor.defaultFormatter": "JakeBecker.elixir-ls",
       "editor.formatOnSave": true
     }
   }
   ```

Now your Elixir files will automatically format when you save them.

## Commit Messages

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic versioning. Your commit messages must follow this format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

| Type | Description | Version Bump |
|------|-------------|--------------|
| `feat` | New feature | Minor (0.X.0) |
| `fix` | Bug fix | Patch (0.0.X) |
| `docs` | Documentation only | None |
| `style` | Code style (formatting, semicolons, etc.) | None |
| `refactor` | Code refactoring | None |
| `perf` | Performance improvement | None |
| `test` | Adding or updating tests | None |
| `build` | Build system or dependencies | None |
| `ci` | CI/CD configuration | None |
| `chore` | Other changes | None |

### Breaking Changes

For breaking changes, add `!` after the type or include `BREAKING CHANGE:` in the footer:

```bash
feat!: remove deprecated API endpoints

# or

feat: update authentication flow

BREAKING CHANGE: JWT tokens now expire after 1 hour instead of 24 hours
```

Breaking changes trigger a major version bump (X.0.0).