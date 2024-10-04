" Title:        Virtual Align
" Description:  Align text using virtualtext.
" Last Change:  18 March 2024
" Maintainer:   Max Nargang <CoffeeCoder1@outlook.com>

if has("nvim-0.10.0") == 0
	echo "Neovim version too old! Switch to v0.10.0 or later to use Virtual Align."
	finish
endif

" Prevents the plugin from being loaded multiple times. If the loaded
" variable exists, do nothing more. Otherwise, assign the loaded
" variable and continue running this instance of the plugin.
if exists("g:loaded_virtualalign")
    finish
endif
let g:loaded_virtualalign = 1

" Exposes the plugin's functions for use as commands in Neovim.
command! -range=% -nargs=1 VirtualAlign lua require("virtual-align").align(<f-args>)
command! -range=% -nargs=0 VirtualAlignAllTest lua require("virtual-align").align_all_test(<f-args>)
command! -nargs=0 VirtualAlignAll lua require("virtual-align").align_all_auto(0, vim.api.nvim_buf_line_count(0))
command! -nargs=0 VirtualAlignEnable lua require("virtual-align").enable()
