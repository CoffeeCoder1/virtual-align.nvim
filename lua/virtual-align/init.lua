local M = {}

local id = 1
local ns_id = vim.api.nvim_create_namespace('virtual-align')

-- Patterns to align on
-- Each has a pattern and a character number where the whitespace should be inserted
local patterns = {
	{pattern = " = \\| += \\| -= \\| \\*= \\| \\*\\*= \\| /= \\| %= \\| &= \\| &&= \\| ||= \\| := \\| |= \\| ^= \\| >>= \\| <<= \\| ??= \\| \\~= ", ws_position = 1},
	{ pattern = " ={2,} \\| < \\| <= \\| > \\| >= \\| != \\| ?? \\| =\\~ ", ws_position = 1 },
	{ pattern = " |\\|-|\\|:|",                                                             ws_position = 1 },
	{ pattern = "; ",                                                                       ws_position = 1 },
	{ pattern = ", ",                                                                       ws_position = 1 }
}

-- Insert whitespace characters at a specified location
function M.insert_whitespace(id, line_num, col_num, chars)
	local bnr = vim.fn.bufnr('%')

	local extmark_opts = {
		id = id,
		virt_text = { { string.rep(" ", chars), "" } },
		virt_text_pos = 'inline',
	}

	local mark_id = vim.api.nvim_buf_set_extmark(bnr, ns_id, line_num, col_num, extmark_opts)
end

-- Align text manually
function M.align(pat)
	local top, bot = vim.fn.getpos("'<"), vim.fn.getpos("'>")
	M.align_lines(pat, top[2] - 1, bot[2])
	vim.fn.setpos("'<", top)
	vim.fn.setpos("'>", bot)
end

-- Align a whole region to one alignment point
function M.align_lines(pat, startline, endline)
	local re = vim.regex(pat)
	local max = -1
	local lines = vim.api.nvim_buf_get_lines(0, startline, endline, false)
	-- Loop through once to find which column things need to be aligned to
	for _, line in pairs(lines) do
		local s = re:match_str(line)
		s = vim.str_utfindex(line, s)
		if s and max < s then
			max = s
		end
	end

	if max == -1 then return end

	-- Loop through again to insert the virtual text
	for i, line in pairs(lines) do
		local s = re:match_str(line)
		s = vim.str_utfindex(line, s)
		if s then
			local rep = max - s
			M.insert_whitespace(id, i - 1, s, rep)
			id = id + 1
		end
	end
end

function M.align_all_auto(startline, endline)
	vim.api.nvim_buf_clear_namespace(0, ns_id, startline, endline)
	for _, e in pairs(patterns) do
		M.align_all(e.pattern, startline, endline, e.ws_position)
	end
	M.align_all_method_blocks(startline, endline)
end

function M.align_all_test()
	local top, bot = vim.fn.getpos("'<"), vim.fn.getpos("'>")
	M.align_all_before(" = ", top[2] - 1, bot[2])
	vim.fn.setpos("'<", top)
	vim.fn.setpos("'>", bot)
end

-- Split up a region into subregions and align those to seperate alignment points
function M.align_all(pat, startline, endline, ws_position)
	local re = vim.regex(pat)
	local max = -1
	local start_line = -1
	local should_align = false
	local all_lines = vim.api.nvim_buf_get_lines(0, startline, endline, false)
	local lines = {}
	-- Iterate through every line in a file
	for i, line in pairs(all_lines) do
		local s = re:match_str(line)
		if s and not (i == #all_lines) then
			should_align = true
			lines[#lines + 1] = line
			if start_line == -1 then start_line = i end
		else -- When reaching the end of a section that needs to be aligned, align the section
			if (i == #all_lines) then lines[#lines + 1] = line end
			if should_align then
				-- Loop through once to find which column things need to be aligned to
				for j, line in pairs(lines) do
					local s = re:match_str(line)
					-- TODO: make work with more than one trailing whitespace character
					local n = vim.str_utfindex(line, s) + ws_position
					local c = vim.fn.virtcol({ start_line + j - 1, n })
					if s and max < c then
						max = c
					end
				end

				for j, line in pairs(lines) do
					local s = re:match_str(line)
					local n = vim.str_utfindex(line, s) + ws_position
					local c = vim.fn.virtcol({ start_line + j - 1, n })
					if s then
						local rep = max - c
						M.insert_whitespace(id, start_line + j - 2, n, rep)
						id = id + 1
					end
				end
				-- Reset variables
				max = -1
				start_line = -1
				should_align = false
				lines = {}
			end
		end
	end
end

-- Split up a region into subregions and align those as a block of period-seperated methods
function M.align_all_method_blocks(startline, endline)
	local re_first = vim.regex("\\.[^.]\\+(.*)")
	local re_following = vim.regex("\\s\\{2,}\\.[^.]\\+\\(\\.*\\)")
	local max = -1
	local start_line = -1
	local should_align = false
	local all_lines = vim.api.nvim_buf_get_lines(0, startline, endline, false)
	local lines = {}
	-- Iterate through every line in a file
	for i, line in pairs(all_lines) do
		local s = re_first:match_str(line)
		if s and not (i == #all_lines) then
			should_align = true
			lines[#lines + 1] = line
			if start_line == -1 then start_line = i end
		else -- When reaching the end of a section that needs to be aligned, align the section
			if (i == #all_lines) then lines[#lines + 1] = line end
			if should_align then
				for j, line in pairs(lines) do
					if j == 1 then
						-- Find which column things need to be aligned to
						local s = re_first:match_str(line)
						-- TODO: make work with more than one trailing whitespace character
						local n = vim.str_utfindex(line, s)
						local c = vim.fn.virtcol({ start_line + j - 1, n })
						max = c
					else
						local s = re_following:match_str(line)
						local n = vim.str_utfindex(line, s) + 2
						local c = vim.fn.virtcol({ start_line + j - 1, n })
						if s then
							local rep = max - c
							M.insert_whitespace(id, start_line + j - 2, n, rep)
							id = id + 1
						end
					end
				end
				-- Reset variables
				max = -1
				start_line = -1
				should_align = false
				lines = {}
			end
		end
	end
end

function M.setup(opts)
	if vim.fn.has('nvim-0.10.0') == 0 then return end

	-- When enabling, align current buffer
	M.align_all_auto(0, vim.api.nvim_buf_line_count(0))

	-- Align automatically
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter", "TextChanged", "TextChangedI" }, {
		callback = function(ev)
			M.align_all_auto(0, vim.api.nvim_buf_line_count(0))
		end
	})
end

return M
