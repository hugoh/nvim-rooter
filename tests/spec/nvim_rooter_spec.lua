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

  -- Add a small helper to track DirChanged events for these tests.
  local function track_dirchanged()
    local pre_count, post_count = 0, 0
    local post_cwd
    local group = vim.api.nvim_create_augroup('nvim_rooter_test_dirchanged_' .. vim.fn.rand(), { clear = true })

    vim.api.nvim_create_autocmd('DirChangedPre', {
      group = group,
      callback = function()
        pre_count = pre_count + 1
      end,
    })

    vim.api.nvim_create_autocmd('DirChanged', {
      group = group,
      callback = function()
        post_count = post_count + 1
        post_cwd = vim.v.event.cwd
      end,
    })

    return {
      get = function()
        return pre_count, post_count, post_cwd
      end,
      clear = function()
        pcall(vim.api.nvim_del_augroup_by_id, group)
      end,
    }
  end

  it('fires DirChangedPre and DirChanged when cwd changes', function()
    rooter.setup({ display_notification = false })
    local testroot, _ = create_test_scenario(true, '/subdir')

    local tracker = track_dirchanged()

    rooter.set_root()

    local pre_count, post_count, post_cwd = tracker.get()
    assert.equals(1, pre_count)
    assert.equals(1, post_count)
    assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(post_cwd))

    tracker.clear()
  end)

  it('does not fire DirChanged events when cwd is unchanged', function()
    rooter.setup({ display_notification = false })
    local _, _ = create_test_scenario(false, '/subdir')

    local tracker = track_dirchanged()

    local initial_dir = vim.fn.getcwd()
    rooter.set_root()
    assert.equals(initial_dir, vim.fn.getcwd())
    local pre_count, post_count = tracker.get()
    assert.equals(0, pre_count)
    assert.equals(0, post_count)

    tracker.clear()
  end)
end)
