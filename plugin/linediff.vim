if exists("g:loaded_linediff") || &cp
  finish
endif

let g:loaded_linediff = '0.1.1' " version number
let s:keepcpo         = &cpo
set cpo&vim

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

    call s:PerformDiff(s:differ_one, s:differ_two)
  else
    call s:differ_one.Reset()
    call s:differ_two.Reset()

    call s:Linediff(a:from, a:to)
  endif
endfunction

command! LinediffReset call s:LinediffReset()
function! s:LinediffReset()
  call s:differ_one.Reset()
  call s:differ_two.Reset()
endfunction

function! s:PerformDiff(one, two)
  call a:one.CreateDiffBuffer("tabedit")
  call a:two.CreateDiffBuffer("rightbelow vsplit")

  let a:one.other_differ = a:two
  let a:two.other_differ = a:one
endfunction
