# AGENTS.md - Neovim Configuration Guidelines

## Upstream Sync Guidance
- `master` tracks upstream `kickstart.nvim`
- `my-nvim` is a custom branch built on top of `master`
- Local config is modularized and may intentionally differ from upstream `init.lua`
- When helping with rebases/upgrades, treat upstream updates as a semantic merge, not a literal file sync
- Preserve local customizations unless explicitly asked to replace them
- For upgrade help, compare upstream behavior with local modules and report:
  1. upstream changes already present,
  2. upstream changes missing locally,
  3. intentional local divergences

## Build/Lint/Test Commands
- **Format Lua**: `stylua .` (formats all Lua files using configured style)
- **Check format**: `stylua --check .` (validates formatting without changes)
- **Health check**: `:checkhealth` (within Neovim to verify plugin/LSP status)
- **Package management**: `:Lazy` (manage plugins), `:Mason` (install LSP servers/tools)

## Code Style Guidelines
- **Indentation**: 2 spaces (never tabs)
- **Line width**: 160 characters max
- **Quotes**: Single quotes preferred (`quote_style = "AutoPreferSingle"`)
- **Function calls**: No parentheses when possible (`call_parentheses = "None"`)
- **Comments**: Use `--` for single line, `--[[]]` for multi-line blocks
- **Plugin structure**: Return tables from plugin files, use `opts = {}` for simple configs

## Naming Conventions
- **Files**: lowercase with hyphens (e.g., `neo-tree.lua`, `todo-comments.lua`)
- **Variables**: snake_case for locals, camelCase for vim options
- **Functions**: snake_case or camelCase consistently within file
- **Keymaps**: Use descriptive `desc` field for all mappings

## Error Handling
- Use `vim.notify()` for user messages
- Prefer `pcall()` for potentially failing operations
- Check plugin availability before configuration

## Import Style
- Use `require 'module'` (single quotes, no parentheses when possible)
- Group requires at top of file or within function scope as needed
- Use relative paths from lua/ directory (e.g., `require 'custom.plugins.oil'`)