let s:differ_one = linediff#differ#New('linediff_one', 1)
let s:differ_two = linediff#differ#New('linediff_two', 2)

function! linediff#Linediff(from, to)
  if s:differ_one.IsBlank()
    call s:differ_one.Init(a:from, a:to)
  elseif s:differ_two.IsBlank()
    call s:differ_two.Init(a:from, a:to)

    call s:PerformDiff()
  else
    call linediff#LinediffReset('!')
    call linediff#Linediff(a:from, a:to)
  endif
endfunction

function! linediff#LinediffReset(bang)
  let force = a:bang == '!'
  call s:differ_one.CloseAndReset(force)
  call s:differ_two.CloseAndReset(force)
endfunction

" The closing logic is a bit roundabout, since changing a buffer in a
" BufUnload autocommand doesn't seem to work.
"
" The process is: if a window is entered after the other differ was destroyed,
" destroy this one as well and close the window.
"
function! s:PerformDiff()
  if g:linediff_diffopt != 'builtin'
    let g:linediff_original_diffopt = &diffopt
    let &diffopt = g:linediff_diffopt
  endif

  call s:differ_one.CreateDiffBuffer(g:linediff_first_buffer_command)
  autocmd BufUnload <buffer> silent call s:differ_one.Reset()
  autocmd WinEnter <buffer> if s:differ_two.IsBlank() | silent call s:differ_one.CloseAndReset(0) | endif

  call s:differ_two.CreateDiffBuffer(g:linediff_second_buffer_command)
  autocmd BufUnload <buffer> silent call s:differ_two.Reset()
  autocmd WinEnter <buffer> if s:differ_one.IsBlank() | silent call s:differ_two.CloseAndReset(0) | endif

  let l:swb_old = &switchbuf
  set switchbuf=useopen,usetab
  " Move to the first diff buffer
  execute 'sbuffer' s:differ_one.diff_buffer
  let &switchbuf = l:swb_old

  let s:differ_one.other_differ = s:differ_two
  let s:differ_two.other_differ = s:differ_one
endfunction
