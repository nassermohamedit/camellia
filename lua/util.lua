local M = {}

M.fs_stat = vim.uv.fs_stat

function M.fs_read(fd, size)
	return vim.uv.fs_read(fd, size, 0)
end

function M.fs_write(fd, data)
	vim.uv.fs_write(fd, data, -1)
end

function M.create(file)
    return vim.uv.fs_open(file, 'w', -1)
end

function M.open_on_write(file)
	return vim.uv.fs_open(file, "w", -1)
end

function M.open_on_read(file)
	return vim.uv.fs_open(file, "r", 438)
end

function M.close(fd)
	vim.uv.fs_close(fd)
end

function M.join(t, sep)
	local out = t[1]
	for i = 2, #t do
		out = string.format("%s%s%s", out, sep, t[i])
	end
	return out
end

function M.add_unique(t, x)
	for _, y in ipairs(t) do
		if x == y then
			return false
		end
	end
	t[#t + 1] = x
    return true
end

function M.is_java(file)
    return "java" == string.sub(file, -4)
end

function M.merge(t1, t2)
    local out = t1
    for i = 1, #t2 do
        out[#out + 1] = t2[i]
    end
    return out
end

function M.with_lsp_classpath(fn, bufnr)
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

function M.get_plugin_dir()
	local info = debug.getinfo(1, "S")
	local script_path = info.source:sub(2)
	local script_dir = script_path:match("(.+)/[^/]*$")
	local parent_dir = script_dir:match("(.+)/[^/]*$")
	return parent_dir
end

function M.save_path(path) end

return M
