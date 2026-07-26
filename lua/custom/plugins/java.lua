-- Java: nvim-java (all-in-one) — jdtls + dap + tests + spring boot + refactors + runner
--
-- IMPORTANT:
--   * Do not add `jdtls` to the servers table in lspconfig.lua — nvim-java owns it.
--   * Do not install nvim-jdtls — nvim-java conflicts with it.
--   * `require('java').setup` must run before `vim.lsp.enable 'jdtls'`.

vim.pack.add {
  {
    src = 'https://github.com/JavaHello/spring-boot.nvim',
    version = '218c0c26c14d99feca778e4d13f5ec3e8b1b60f0',
  },
  'https://github.com/MunifTanjim/nui.nvim',
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/nvim-java/nvim-java',
}

-- Discover JDKs installed via sdkman.
-- Picks the newest patch per major, names them with Eclipse execution-environment
-- ids, and marks sdkman's active JDK (`current`) as the default. Returns an empty
-- list on machines without sdkman, where jdtls just uses $JAVA_HOME / PATH.
local function detect_sdkman_jdks()
  local root = (vim.env.SDKMAN_DIR or (vim.uv.os_homedir() .. '/.sdkman')) .. '/candidates/java'
  if vim.fn.isdirectory(root) == 0 then return { runtimes = {}, launcher = nil } end

  local function tuple(name)
    local a, b, c = name:match '^(%d+)%.?(%d*)%.?(%d*)'
    return { tonumber(a) or 0, tonumber(b) or 0, tonumber(c) or 0 }
  end
  local function gt(x, y)
    for i = 1, 3 do
      if x[i] ~= y[i] then return x[i] > y[i] end
    end
    return false
  end

  local current = vim.uv.fs_realpath(root .. '/current')
  local best, current_major = {}, nil

  for name, ftype in vim.fs.dir(root) do
    local path = root .. '/' .. name
    if name ~= 'current' and (ftype == 'directory' or vim.fn.isdirectory(path) == 1) then
      local t = tuple(name)
      local major = t[1]
      if major > 0 then
        if current and vim.uv.fs_realpath(path) == current then current_major = major end
        if not best[major] or gt(t, best[major].tuple) then best[major] = { path = path, tuple = t } end
      end
    end
  end

  -- Default runtime follows sdkman's active JDK, falling back to the newest major.
  local default_major = current_major
  if not default_major then
    for major in pairs(best) do
      if not default_major or major > default_major then default_major = major end
    end
  end

  local runtimes, launcher = {}, nil
  for major, info in pairs(best) do
    runtimes[#runtimes + 1] = {
      name = major == 8 and 'JavaSE-1.8' or ('JavaSE-' .. major),
      path = info.path,
      default = (major == default_major) or nil,
    }
    -- jdtls itself must run on JDK 17+; keep the newest suitable one.
    if major >= 17 and (not launcher or gt(info.tuple, launcher.tuple)) then launcher = info end
  end
  table.sort(runtimes, function(a, b) return a.name < b.name end)

  -- Prefer sdkman's active JDK to run jdtls when it is itself 17+.
  if current and current_major and current_major >= 17 then launcher = { path = current } end

  return { runtimes = runtimes, launcher = launcher and launcher.path or nil }
end

local jdk = detect_sdkman_jdks()

require('java').setup {
  jdk = {
    -- Use an installed JDK to run jdtls; only fall back to a download if none found.
    auto_install = jdk.launcher == nil,
    path = jdk.launcher,
  },
}

-- Make jdtls emit method parameter names, matching `javac -parameters` (which
-- Spring Boot's Gradle plugin enables). Eclipse JDT omits the MethodParameters
-- bytecode attribute by default, so classes it compiles into `bin/main` (what the
-- nvim-java runner executes) break Spring SpEL that resolves parameters by name,
-- e.g. `@Cacheable(key = '#id')` -> "Null key returned". A workspace preferences
-- file referenced via `java.settings.url` applies this to every project.
local jdt_prefs = vim.fs.joinpath(vim.fn.stdpath 'cache', 'jdtls', 'eclipse-jdt.prefs')
do
  local content = 'org.eclipse.jdt.core.compiler.codegen.methodParameters=generate\n'
  local fd = io.open(jdt_prefs, 'r')
  local current = fd and fd:read '*a'
  if fd then fd:close() end
  if current ~= content then
    vim.fn.mkdir(vim.fs.dirname(jdt_prefs), 'p')
    local out = assert(io.open(jdt_prefs, 'w'))
    out:write(content)
    out:close()
  end
end

vim.lsp.config('jdtls', {
  settings = {
    java = {
      configuration = {
        runtimes = jdk.runtimes,
      },
      -- Workspace-wide Eclipse compiler prefs (see jdt_prefs above).
      settings = {
        url = jdt_prefs,
      },
    },
  },
})

vim.lsp.enable 'jdtls'

local java_keymaps = vim.api.nvim_create_augroup('custom-java-keymaps', { clear = true })

vim.api.nvim_create_autocmd('FileType', {
  group = java_keymaps,
  pattern = 'java',
  callback = function(args)
    local map = function(lhs, rhs, desc) vim.keymap.set('n', lhs, rhs, { buffer = args.buf, desc = desc }) end

    map('<leader>jr', '<cmd>JavaRunnerRunMain<cr>', '[J]ava [R]un main')
    map('<leader>js', '<cmd>JavaRunnerStopMain<cr>', '[J]ava [S]top main')
    map('<leader>jl', '<cmd>JavaRunnerToggleLogs<cr>', '[J]ava toggle [L]ogs')

    map('<leader>jtc', '<cmd>JavaTestRunCurrentClass<cr>', '[J]ava [T]est [C]lass')
    map('<leader>jtm', '<cmd>JavaTestRunCurrentMethod<cr>', '[J]ava [T]est [M]ethod')
    map('<leader>jtd', '<cmd>JavaTestDebugCurrentClass<cr>', '[J]ava [T]est [D]ebug class')
    map('<leader>jtr', '<cmd>JavaTestViewLastReport<cr>', '[J]ava [T]est [R]eport')
    map('<leader>jta', '<cmd>JavaTestRunAllTests<cr>', '[J]ava [T]est run [A]ll')
    map('<leader>jtA', '<cmd>JavaTestDebugAllTests<cr>', '[J]ava [T]est debug all')

    map('<leader>jev', '<cmd>JavaRefactorExtractVariable<cr>', '[J]ava [E]xtract [V]ariable')
    map('<leader>jem', '<cmd>JavaRefactorExtractMethod<cr>', '[J]ava [E]xtract [M]ethod')
    map('<leader>jec', '<cmd>JavaRefactorExtractConstant<cr>', '[J]ava [E]xtract [C]onstant')

    map('<leader>jp', '<cmd>JavaProfile<cr>', '[J]ava [P]rofile UI')
    map('<leader>jR', '<cmd>JavaSettingsChangeRuntime<cr>', '[J]ava change [R]untime')
    map('<leader>jb', '<cmd>JavaBuildBuildWorkspace<cr>', '[J]ava [B]uild workspace')
  end,
})

local ok, wk = pcall(require, 'which-key')
if ok then wk.add {
  { '<leader>j', group = '[J]ava', mode = 'n' },
} end
