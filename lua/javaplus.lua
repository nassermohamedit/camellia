local util = require("util")

local data_dir = string.format("%s/javaplus", vim.fn.stdpath("data"))

local augroup = vim.api.nvim_create_augroup("Javaplus", { clear = true })

local project_name

local classpath = {}

local function save_paths()
	local fd = util.open_on_write(string.format("%s/%s", data_dir, project_name))
	local data = util.join(classpath, "\n")
	util.fs_write(fd, data)
end

local function try_read_paths()
	local data_file = string.format("%s/%s", data_dir, project_name)
	local stat = util.fs_stat(data_file)
	if stat and not vim.tbl_isempty(stat) then
		local fd = util.open_on_read(data_file)
		local data = util.fs_read(fd, stat.size)
		data = string.gsub(data, "\r", "")
		classpath = vim.split(data, "\n")
	else
		if not stat then
			util.create(data_file)
		end
		return
	end
end

local function setup()
	local project_path = vim.fn.getcwd()
	project_name = project_path:match("([^/\\]+)$")
	try_read_paths()
end

local function add_to_classpath(...)
	local args = { ... }
	if #args == 0 then
		local bufnr = vim.api.nvim_get_current_buf()
		local file = vim.api.nvim_buf_get_name(bufnr)
		local path = vim.fn.fnamemodify(file, ":h")
		-- This is based on string comparaision.
		-- TODO - probably Path comparaison should be used.
		if util.add_unique(classpath, path) then
			save_paths()
		end
	end
	-- TODO - Support adding paths specified as argumetns
end

local function run_main()
	local bufnr = vim.api.nvim_get_current_buf()
	local javafile = vim.api.nvim_buf_get_name(bufnr)
	if not util.is_java(javafile) then
		print("Not java file")
		return
	end
	local rjr = util.get_plugin_dir() .. "/rjr/rjr.sh"
	util.with_lsp_classpath(function(lsp_paths)
		local cp
		if lsp_paths and #lsp_paths > 0 then
			cp = util.merge(lsp_paths, classpath)
		else
			cp = classpath
		end
		cp = util.join(cp, ":")
		local buf = vim.api.nvim_create_buf(true, true)
		vim.api.nvim_win_set_buf(0, buf)
		vim.fn.termopen(rjr .. " -cp " .. cp .. " " .. javafile)
	end, bufnr)
end

return {
	setup = setup,
	add_to_classpath = add_to_classpath,
	run_main = run_main,
}
