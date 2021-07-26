set rtp+=~/AppData/Local/nvim/plugged/ctrlf
fun! CtrlF()
	lua for k in pairs(package.loaded) do if k:match("^ctrlf") then package.loaded[k] = nil end end
	lua require("ctrlf").ctrlf()
endfun

nnoremap <c-s> <cmd>call CtrlF()<cr>
augroup CtrlF
	autocmd!
augroup END
