if exists('g:loaded_linediff') || &cp
  finish
endif

let g:loaded_linediff = '0.1.1' " version number
let s:keepcpo         = &cpo
set cpo&vim

if !exists('g:linediff_indent')
  let g:linediff_indent = 0
endif

" Initialized lazily to avoid executing the autoload file before it's really
" needed.
function! s:Init()
  if !exists('s:differ_one')
    let s:differ_one = linediff#differ#New('linediff_one', 1)
    let s:differ_two = linediff#differ#New('linediff_two', 2)
  endif
endfunction

command! -range Linediff call s:Linediff(<line1>, <line2>)
function! s:Linediff(from, to)
  call s:Init()

  if s:differ_one.IsBlank()
    call s:differ_one.Init(a:from, a:to)
  elseif s:differ_two.IsBlank()
    call s:differ_two.Init(a:from, a:to)

    call s:PerformDiff()
  else
    call s:LinediffReset()
    call s:Linediff(a:from, a:to)
  endif
endfunction

command! LinediffReset call s:LinediffReset()
function! s:LinediffReset()
  call s:differ_one.CloseAndReset()
  call s:differ_two.CloseAndReset()
endfunction

function! s:PerformDiff()
  call s:differ_one.CreateDiffBuffer("tabedit")
  autocmd BufUnload <buffer> silent call s:differ_one.Reset() | silent call s:differ_two.Reset()

  call s:differ_two.CreateDiffBuffer("rightbelow vsplit")
  autocmd BufUnload <buffer> silent call s:differ_two.Reset() | silent call s:differ_one.Reset()

  wincmd t " move to the first diff buffer

  let s:differ_one.other_differ = s:differ_two
  let s:differ_two.other_differ = s:differ_one
endfunction
