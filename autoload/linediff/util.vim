" Helper method to change to a certain buffer.
function! linediff#util#SwitchBuffer(bufno)
  exe "buffer ".a:bufno
endfunction
