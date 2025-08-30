describe('nvim-rooter', function()
  local rooter = require('nvim_rooter')
  local cache_key = 'nvim-rooter:repo_name'
  local testroots = {} -- Track temp directories for cleanup

  local function create_test_scenario(has_git, subdir)
    subdir = subdir or ''
    local testroot = vim.fn.tempname()
    table.insert(testroots, testroot) -- Add to cleanup list
    if has_git then
      vim.fn.mkdir(testroot .. '/.git', 'p')
    end
    local file_path = testroot .. subdir .. '/file.txt'
    vim.cmd('edit ' .. file_path)
    return testroot, file_path
  end

  before_each(function()
    rooter.setup({ display_notification = false })
    vim.b[cache_key] = nil
  end)

  after_each(function()
    for _, root in ipairs(testroots) do
      vim.fn.delete(root, 'rf')
    end
    testroots = {}
  end)

  it(('does not find anything'), function()
    local testroot, file_path = create_test_scenario(false, '/subdir')
    local initial_dir = vim.fn.getcwd()
    rooter.set_root()
    assert.equals('', rooter.repo_name())
    assert.equals(initial_dir, vim.fn.getcwd())
  end)

  it('finds root directory', function()
    local testroot, file_path = create_test_scenario(true, '/subdir')
    rooter.set_root()
    assert.equals(vim.fn.fnamemodify(testroot, ':t'), rooter.repo_name())
    assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(vim.fn.getcwd()))
  end)

  it('caches repo name', function()
    local testroot = create_test_scenario(true)
    rooter.repo_name()
    local bufnr = vim.api.nvim_get_current_buf()
    local cache = vim.api.nvim_buf_get_var(bufnr, cache_key)
    assert.equals(vim.fn.fnamemodify(testroot, ':t'), cache)
  end)

  it('skips excluded filetypes', function()
    rooter.setup({ excluded_filetypes = { text = true } })
    local initial_dir = vim.fn.getcwd()
    local testroot = create_test_scenario(true)
    assert.equals(vim.fn.fnamemodify(testroot, ':t'), rooter.repo_name())
    assert.equals(initial_dir, vim.fn.getcwd())
  end)

  it('shows notification when enabled', function()
    rooter.setup({ display_notification = true })
    local testroot = create_test_scenario(true)
    local dirname = vim.fn.fnamemodify(testroot, ':t')
    assert.matches('%[cwd%] .*', vim.fn.execute('messages'))
  end)
end)
