" Initialized lazily to avoid executing the autoload file before it's really
" needed.
"
" TODO Experiment to see if this matters at all.
"
function! s:Init()
  if !exists('s:first_buffer')
    let s:first_buffer  = linediff#BlankBufferData()
    let s:second_buffer = linediff#BlankBufferData()
  endif
endfunction

command! -range Linediff call s:Linediff(<line1>, <line2>)
function! s:Linediff(from, to)
  call s:Init()

  if s:first_buffer.IsBlank()
    call s:first_buffer.Init({
          \ 'bufno':    bufnr('%'),
          \ 'filetype': &filetype,
          \ 'from':     a:from,
          \ 'to':       a:to
          \ })
  elseif s:second_buffer.IsBlank()
    call s:second_buffer.Init({
          \ 'bufno':    bufnr('%'),
          \ 'filetype': &filetype,
          \ 'from':     a:from,
          \ 'to':       a:to
          \ })

    call s:PerformDiff(s:first_buffer, s:second_buffer)
  else
    call s:first_buffer.Reset()
    call s:second_buffer.Reset()
    call s:Linediff(a:from, a:to)
  endif
endfunction

function! s:PerformDiff(first, second)
  call s:CreateDiffBuffer(a:first, "tabedit")
  call s:CreateDiffBuffer(a:second, "rightbelow vsplit")
endfunction

function! s:CreateDiffBuffer(buffer, edit_command)
  " TODO inline:
  let content   = getbufline(a:buffer.bufno, a:buffer.from, a:buffer.to)
  let temp_file = tempname()

  exe a:edit_command . " " . temp_file
  call append(0, content)
  normal! Gdd
  set nomodified

  " TODO inline:
  call s:SetupDiffBuffer(a:buffer.bufno, a:buffer.filetype, a:buffer.from, a:buffer.to)
  diffthis
endfunction

function! s:SetupDiffBuffer(bufno, ft, from, to)
  let b:original_buffer = a:bufno
  let b:from            = a:from
  let b:to              = a:to

  let statusline = printf('[%s:%d-%d]', bufname(b:original_buffer), b:from, b:to)
  if &statusline =~ '%f'
    let statusline = substitute(&statusline, '%f', statusline, '')
  endif
  exe "setlocal statusline=".escape(statusline, ' ')
  exe "set filetype=".a:ft
endfunction
