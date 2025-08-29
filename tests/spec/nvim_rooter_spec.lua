describe('nvim-rooter', function()
  local rooter = require('nvim_rooter')
  local cache_key = 'nvim-rooter:repo_name'

  local function create_test_scenario(has_git, subdir)
    subdir = subdir or ''
    local testroot = vim.fn.tempname()
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

  it(('does not find anything'), function()
    local testroot = create_test_scenario(false, '/subdir')
    assert.equals('', rooter.repo_name())
  end)

  it('finds root directory', function()
    local testroot = create_test_scenario(true, '/subdir')
    assert.equals(vim.fn.fnamemodify(testroot, ':t'), rooter.repo_name())
  end)

  it('caches repo name', function()
    local testroot = create_test_scenario(true)
    rooter.repo_name()
    local bufnr = vim.api.nvim_get_current_buf()
    local cache = vim.api.nvim_buf_get_var(bufnr, cache_key)

    assert.equals(vim.fn.fnamemodify(testroot, ':t'), cache)
  end)

  it('skips excluded filetypes', function()
    rooter.setup({ excluded_filetypes = { help = true } })
    vim.bo.filetype = 'help'

    local testroot = create_test_scenario(true)
    assert.equals(vim.fn.fnamemodify(testroot, ':t'), rooter.repo_name())
  end)

  it('shows notification when enabled', function()
    rooter.setup({ display_notification = true })
    local testroot = create_test_scenario(true)
    local dirname = vim.fn.fnamemodify(testroot, ':t')
    assert.is_not_nil(string.find(vim.fn.execute('messages'), 'working directory = .*' .. dirname))
  end)
end)
