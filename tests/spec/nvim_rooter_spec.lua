describe("nvim-rooter", function()
	local rooter = require("nvim_rooter")
	local testroots = {} -- Track temp directories for cleanup
	local initial_cwd = vim.fn.getcwd()

	local function create_test_scenario(has_git, subdir)
		subdir = subdir or ""
		local testroot = vim.fn.resolve(vim.fn.tempname())
		table.insert(testroots, testroot) -- Add to cleanup list
		vim.fn.mkdir(testroot .. subdir, "p")
		if has_git then vim.fn.mkdir(testroot .. "/.git", "p") end
		local file_path = testroot .. subdir .. "/file.txt"
		vim.cmd("edit " .. file_path)
		return testroot, file_path
	end

	before_each(function()
		rooter.setup({ auto = false, display_notification = false })
		vim.api.nvim_set_current_dir(initial_cwd)
	end)

	after_each(function()
		for _, root in ipairs(testroots) do
			vim.fn.delete(root, "rf")
		end
		testroots = {}
		vim.api.nvim_set_current_dir(initial_cwd)
	end)

	it("does not find anything", function()
		create_test_scenario(false, "/subdir")
		local current_dir = vim.fn.getcwd()
		rooter.set_root()
		assert.equals(current_dir, vim.fn.getcwd())
	end)

	it("finds root directory", function()
		local testroot, _ = create_test_scenario(true, "/subdir")
		rooter.set_root()
		assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(vim.fn.getcwd()))
	end)

	it("shows notification when enabled", function()
		rooter.setup({ auto = true, display_notification = true })
		create_test_scenario(true)
		assert.matches("%[cwd%] .*", vim.fn.execute("messages"))
	end)

	-- Add a small helper to track DirChanged events for these tests.
	local function track_dirchanged()
		local pre_count, post_count = 0, 0
		local post_cwd
		local group = vim.api.nvim_create_augroup("nvim_rooter_test_dirchanged_" .. vim.fn.rand(), { clear = true })

		vim.api.nvim_create_autocmd("DirChangedPre", {
			group = group,
			callback = function() pre_count = pre_count + 1 end,
		})

		vim.api.nvim_create_autocmd("DirChanged", {
			group = group,
			callback = function()
				post_count = post_count + 1
				post_cwd = vim.v.event.cwd
			end,
		})

		return {
			get = function() return pre_count, post_count, post_cwd end,
			clear = function() pcall(vim.api.nvim_del_augroup_by_id, group) end,
		}
	end

	it("fires DirChangedPre and DirChanged when cwd changes", function()
		rooter.setup({ auto = false, display_notification = false })
		local testroot, _ = create_test_scenario(true, "/subdir")

		local tracker = track_dirchanged()

		rooter.set_root()

		local pre_count, post_count, post_cwd = tracker.get()
		assert.equals(1, pre_count)
		assert.equals(1, post_count)
		assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(post_cwd))

		tracker.clear()
	end)

	it("does not fire DirChanged events when cwd is unchanged", function()
		rooter.setup({ auto = false, display_notification = false })
		local _, _ = create_test_scenario(false, "/subdir")

		local tracker = track_dirchanged()

		local current_dir = vim.fn.getcwd()
		rooter.set_root()
		assert.equals(current_dir, vim.fn.getcwd())
		local pre_count, post_count = tracker.get()
		assert.equals(0, pre_count)
		assert.equals(0, post_count)

		tracker.clear()
	end)

	it("get_root returns root directory when found", function()
		rooter.setup({ auto = false, display_notification = false })
		local testroot, _ = create_test_scenario(true, "/subdir")
		local root = rooter.get_root()
		assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(root))
	end)

	it("get_root returns nil when no root found", function()
		rooter.setup({ auto = false, display_notification = false })
		create_test_scenario(false, "/subdir")
		local root = rooter.get_root()
		assert.is_nil(root)
	end)

	it("is_cwd_root returns true when cwd is root", function()
		rooter.setup({ auto = false, display_notification = false })
		local testroot = vim.fn.resolve(vim.fn.tempname())
		vim.fn.mkdir(testroot .. "/.git", "p")
		vim.api.nvim_set_current_dir(testroot)
		local file_path = testroot .. "/subdir/file.txt"
		vim.fn.mkdir(testroot .. "/subdir", "p")
		vim.cmd("edit " .. file_path)
		table.insert(testroots, testroot)
		local is_root, root = rooter.is_cwd_root()
		assert.is_true(is_root)
		assert.equals(testroot, vim.fn.resolve(root))
	end)

	it("is_cwd_root returns false when cwd is not root", function()
		rooter.setup({ auto = false, display_notification = false })
		local testroot, _ = create_test_scenario(true, "/subdir")
		local is_root, root = rooter.is_cwd_root()
		assert.is_false(is_root)
		assert.is_not_nil(root)
	end)

	it("is_cwd_root returns false when no root found", function()
		rooter.setup({ auto = false, display_notification = false })
		create_test_scenario(false, "/subdir")
		local is_root, root = rooter.is_cwd_root()
		assert.is_false(is_root)
		assert.is_nil(root)
	end)

	it("prompts when confirm is true and changes cwd on yes", function()
		local confirm_called = false
		local original_confirm = vim.fn.confirm
		local function mock_confirm()
			confirm_called = true
			return 1
		end
		vim.fn.confirm = mock_confirm

		rooter.setup({ auto = false, confirm = true, display_notification = false })
		local testroot, _ = create_test_scenario(true, "/subdir")

		rooter.set_root()

		vim.fn.confirm = original_confirm
		assert.is_true(confirm_called)
		assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(vim.fn.getcwd()))
	end)

	it("does not change cwd when confirm is true and user declines", function()
		local original_confirm = vim.fn.confirm
		local function mock_confirm() return 2 end
		vim.fn.confirm = mock_confirm

		rooter.setup({ auto = false, confirm = true, display_notification = false })
		create_test_scenario(true, "/subdir")
		local initial_dir = vim.fn.getcwd()

		rooter.set_root()

		vim.fn.confirm = original_confirm
		assert.equals(initial_dir, vim.fn.getcwd())
	end)
end)
