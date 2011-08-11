function! s:Init()
  let s:first_buffer  = linediff#InitBufferData()
  let s:second_buffer = linediff#InitBufferData()
endfunction

command! -range Linediff call s:Linediff(<line1>, <line2>)
function! s:Linediff(from, to)
  call s:Init()

  " TODO
endfunction
