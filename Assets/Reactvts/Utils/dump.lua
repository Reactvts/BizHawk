DEFAULT_CMD_OUTPUT = '.cmd-output.txt'

-- determine operating system for the purpose of commands
_PLATFORMS = {['dll'] = 'WIN', ['so'] = 'LINUX', ['dylib'] = 'MAC'}
PLATFORM = _PLATFORMS[(package.cpath..';'):match('%.(%a+);')]


function dump(o)
	function _dump(o, a, b)
		if type(o) == 'table' then
			local s = ''
			for k,v in pairs(o) do
				s = s..a..string.format('[%s] = %s,', _dump(k, "", ""), _dump(v, "", ""))..b
			end
			return '{'..b..s..'}'..b
		elseif type(o) == 'number' or type(o) == 'boolean' or o == nil then
			return tostring(o)
		elseif type(o) == 'string' then
			-- %q encloses in double quotes and escapes according to lua rules
			return string.format('%q', o)
		else -- functions, native objects, coroutines
			error(string.format('Unsupported value of type "%s" in config.', type(o)))
		end
	end

	return _dump(o, "\t", "\n")
end


function write_data(filename, data, mode)
	local handle, err = io.open(filename, mode or 'w')
	if handle == nil then
		log_message(string.format("Couldn't write to file: %s", filename))
		log_message(err)
		return
	end
	handle:write(data)
	handle:close()
end

local IGNORED_FILE_EXTS = { '.gitignore'}

-- returns a table containing all files in a given directory
function get_dir_contents(dir, tmp, force)
	local TEMP_FILE = tmp or DEFAULT_CMD_OUTPUT
	if force ~= false or not path_exists(TEMP_FILE) then
		local cmd = string.format('ls "%s" -p | grep -v / > %s', dir, TEMP_FILE)
		if PLATFORM == 'WIN' then
			cmd = string.format('dir "%s" /B /A-D > %s', dir, TEMP_FILE)
		end
		print(cmd)
		os.execute(cmd)
	end

	local file_list = {}
	local fp = io.open(TEMP_FILE, 'r')
	for x in fp:lines() do
		table.insert(file_list, x)
	end
	fp:close()
	return file_list
end
