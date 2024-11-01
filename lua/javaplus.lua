local augroup = vim.api.nvim_create_augroup("Javaplus", { clear = true })

local classpath

local function register_base()
	classpath = vim.fn.getcwd()
end

local function setup()
	vim.api.nvim_create_autocmd("VimEnter", { group = augroup, desc = "", once = true, callback = register_base })
end

local function add_to_classpath(...)
	local args = { ... }
	if #args == 0 then
		local bufnr = vim.api.nvim_get_current_buf()
		local file = vim.api.nvim_buf_get_name(bufnr)
		local path = vim.fn.fnamemodify(file, ":h")
		classpath = classpath .. ":" .. path
	end
	-- TODO - Support adding paths specofoed as argumetns
end

local function get_plugin_dir()
	local info = debug.getinfo(1, "S")
	local script_path = info.source:sub(2)
	local script_dir = script_path:match("(.+)/[^/]*$")
	local parent_dir = script_dir:match("(.+)/[^/]*$")
	return parent_dir
end

local function with_lsp_classpath(fn, bufnr)
	if not bufnr then
		bufnr = 0
	end
	local uri = vim.uri_from_bufnr(bufnr)
	local options = vim.fn.json_encode({ scope = "runtime" })
	local cmd = {
		command = "java.project.getClasspaths",
		arguments = { uri, options },
	}
	local clients = {}
	local candidates = vim.lsp.get_clients({ bufnr = bufnr })
	for _, c in pairs(candidates) do
		local command_provider = c.server_capabilities.executeCommandProvider
		local commands = type(command_provider) == "table" and command_provider.commands or {}
		if vim.tbl_contains(commands, cmd.command) then
			table.insert(clients, c)
		end
	end
	local num_clients = vim.tbl_count(clients)
	if num_clients == 0 then
        fn(nil)
        return
	end
	coroutine.wrap(function()
		local co = coroutine.running()
		local callback = function(err, resp)
			coroutine.resume(co, err, resp)
		end
		clients[1].request("workspace/executeCommand", cmd, callback, bufnr)
		local _, resp = coroutine.yield()
		fn(resp.classpaths)
	end)()
end

local function run_main()
	local bufnr = vim.api.nvim_get_current_buf()
	local javafile = vim.api.nvim_buf_get_name(bufnr)
	local rjr = get_plugin_dir() .. "/rjr.sh"
	with_lsp_classpath(function(lsp_paths)
		local cp = classpath
		if lsp_paths then
			cp = cp .. ":" .. table.concat(lsp_paths, ":")
		end
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
