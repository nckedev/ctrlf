set rtp+=~/AppData/Local/nvim/plugged/ctrlf
set rtp+=~/.config/nvim/plugged/ctrlf
fun! CtrlF()
	lua for k in pairs(package.loaded) do if k:match("^ctrlf") then package.loaded[k] = nil end end
	lua require("ctrlf").ctrlf()
endfun

noremap <c-f> <cmd>call CtrlF()<cr>
noremap <tab> <cmd>lua require("ctrlf").ctrlf_next()<cr>
noremap <s-tab> <cmd>lua require("ctrlf").ctrlf_next(true)<cr>
augroup CtrlF
	autocmd!
augroup END
