" Initialized lazily to avoid executing the autoload file before it's really
" needed.
"
" TODO Experiment to see if this matters at all.
"
function! s:Init()
  if !exists('s:first_differ')
    let s:first_differ  = linediff#BlankDiffer('linediff_one', 1)
    let s:second_differ = linediff#BlankDiffer('linediff_two', 2)
  endif
endfunction

command! -range Linediff call s:Linediff(<line1>, <line2>)
function! s:Linediff(from, to)
  call s:Init()

  if s:first_differ.IsBlank()
    call s:first_differ.Init(a:from, a:to)
  elseif s:second_differ.IsBlank()
    call s:second_differ.Init(a:from, a:to)

    call s:PerformDiff(s:first_differ, s:second_differ)
  else
    call s:first_differ.Reset()
    call s:second_differ.Reset()

    call s:Linediff(a:from, a:to)
  endif
endfunction

command! LinediffReset call s:LinediffReset()
function! s:LinediffReset()
  call s:first_differ.Reset()
  call s:second_differ.Reset()
endfunction

function! s:PerformDiff(first, second)
  call s:CreateDiffBuffer(a:first, "tabedit")
  call s:CreateDiffBuffer(a:second, "rightbelow vsplit")
endfunction

function! s:CreateDiffBuffer(differ, edit_command)
  let lines     = a:differ.Lines()
  let temp_file = tempname()

  exe a:edit_command . " " . temp_file
  call append(0, lines)
  normal! Gdd
  set nomodified

  call a:differ.SetupDiffBuffer()

  diffthis
endfunction
