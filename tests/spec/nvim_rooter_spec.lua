describe("nvim-rooter", function()
	local rooter = require("nvim_rooter")
	local testroots = {} -- Track temp directories for cleanup

	local function create_test_scenario(has_git, subdir)
		subdir = subdir or ""
		local testroot = vim.fn.tempname()
		table.insert(testroots, testroot) -- Add to cleanup list
		if has_git then vim.fn.mkdir(testroot .. "/.git", "p") end
		local file_path = testroot .. subdir .. "/file.txt"
		vim.cmd("edit " .. file_path)
		return testroot, file_path
	end

	before_each(function() rooter.setup({ display_notification = false }) end)

	after_each(function()
		for _, root in ipairs(testroots) do
			vim.fn.delete(root, "rf")
		end
		testroots = {}
	end)

	it("does not find anything", function()
		create_test_scenario(false, "/subdir")
		local initial_dir = vim.fn.getcwd()
		rooter.set_root()
		assert.equals(initial_dir, vim.fn.getcwd())
	end)

	it("finds root directory", function()
		local testroot, _ = create_test_scenario(true, "/subdir")
		rooter.set_root()
		assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(vim.fn.getcwd()))
	end)

	it("shows notification when enabled", function()
		rooter.setup({ display_notification = true })
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
		rooter.setup({ display_notification = false })
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
		rooter.setup({ display_notification = false })
		local _, _ = create_test_scenario(false, "/subdir")

		local tracker = track_dirchanged()

		local initial_dir = vim.fn.getcwd()
		rooter.set_root()
		assert.equals(initial_dir, vim.fn.getcwd())
		local pre_count, post_count = tracker.get()
		assert.equals(0, pre_count)
		assert.equals(0, post_count)

		tracker.clear()
	end)

	it("prompts when confirm is true and changes cwd on yes", function()
		local confirm_called = false
		local original_confirm = vim.fn.confirm
		local function mock_confirm(msg, opts, default)
			confirm_called = true
			return 1
		end
		vim.fn.confirm = mock_confirm

		rooter.setup({ confirm = true, display_notification = false })
		local testroot, _ = create_test_scenario(true, "/subdir")

		rooter.set_root()

		vim.fn.confirm = original_confirm
		assert.is_true(confirm_called)
		assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(vim.fn.getcwd()))
	end)

	it("does not change cwd when confirm is true and user declines", function()
		local original_confirm = vim.fn.confirm
		local function mock_confirm(sg, opts, default) return 2 end
		vim.fn.confirm = mock_confirm

		rooter.setup({ confirm = true, display_notification = false })
		create_test_scenario(true, "/subdir")
		local initial_dir = vim.fn.getcwd()

		vim.api.nvim_get_current_buf()

		rooter.set_root()

		vim.fn.confirm = original_confirm
		assert.equals(initial_dir, vim.fn.getcwd())
	end)

	describe("scope", function()
		it("uses nvim scope by default (global cwd)", function()
			rooter.setup({ scope = "nvim", display_notification = false })
			local testroot, _ = create_test_scenario(true, "/subdir")

			rooter.set_root()

			assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(vim.fn.getcwd()))
		end)

		it("changes tab local directory with tab scope", function()
			rooter.setup({ scope = "tab", display_notification = false })
			local testroot, _ = create_test_scenario(true, "/subdir")
			local initial_cwd = vim.fn.getcwd()

			rooter.set_root()

			assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(vim.fn.getcwd(vim.api.nvim_get_current_tabpage())))
			assert.equals(initial_cwd, vim.fn.getcwd())
		end)

		it("uses correct function for win scope", function()
			-- Mock nvim_win_set_option to verify it's called
			local win_set_option_called = false
			local original_win_set_option = vim.api.nvim_win_set_option
			local called_with_dir = nil

			function vim.api.nvim_win_set_option(winid, option, value)
				if option == "cd" then
					win_set_option_called = true
					called_with_dir = value
				end
			end

			rooter.setup({ scope = "win", display_notification = false })
			local testroot, _ = create_test_scenario(true, "/subdir")

			rooter.set_root()

			vim.api.nvim_win_set_option = original_win_set_option

			assert.is_true(win_set_option_called)
			assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(called_with_dir))
		end)

		it("falls back to nvim scope for invalid scope", function()
			rooter.setup({ scope = "invalid_scope", display_notification = false })
			local testroot, _ = create_test_scenario(true, "/subdir")

			rooter.set_root()

			assert.equals(vim.fn.resolve(testroot), vim.fn.resolve(vim.fn.getcwd()))
		end)
	end)
end)
