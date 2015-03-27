if exists('g:loaded_linediff') || &cp
  finish
endif

let g:loaded_linediff = '0.2.0' " version number
let s:keepcpo         = &cpo
set cpo&vim

if !exists('g:linediff_indent')
  let g:linediff_indent = 0
endif

if !exists('g:linediff_buffer_type')
  " One of: 'tempfile', 'scratch'
  let g:linediff_buffer_type = 'tempfile'
endif

if !exists('g:linediff_first_buffer_command')
  let g:linediff_first_buffer_command = 'tabnew'
endif

if !exists('g:linediff_second_buffer_command')
  let g:linediff_second_buffer_command = 'rightbelow vertical new'
endif

" Initialized lazily to avoid executing the autoload file before it's really
" needed.
function! s:Init()
  if !s:IsInitialized()
    let s:differ_one = linediff#differ#New('linediff_one', 1)
    let s:differ_two = linediff#differ#New('linediff_two', 2)
  endif
endfunction

command! -range Linediff call s:Linediff(<line1>, <line2>)
function! s:Linediff(from, to, ...)
  if a:0 > 0
    let options = a:1
  else
    let options = {}
  endif

  call s:Init()

  if s:differ_one.IsBlank()
    call s:differ_one.Init(a:from, a:to, options)
  elseif s:differ_two.IsBlank()
    call s:differ_two.Init(a:from, a:to, options)

    call s:PerformDiff()
  else
    call s:LinediffReset('!')
    call s:Linediff(a:from, a:to, options)
  endif
endfunction

command! LinediffMerge call s:LinediffMerge()
function! s:LinediffMerge()
  let areas = s:FindMergeMarkers()

  if empty(areas)
    echomsg "Couldn't find merge markers around cursor"
    return
  endif

  let [top_area, bottom_area] = areas

  let merge_range = [top_area[0] - 1, bottom_area[1] + 1]

  call s:Linediff(top_area[0],    top_area[1],    {'merge': merge_range})
  call s:Linediff(bottom_area[0], bottom_area[1], {'merge': merge_range})
endfunction

command! LinediffPick call s:LinediffPick()
function! s:LinediffPick()
  if !exists('b:differ')
    echomsg "Not in a Linediff diff buffer, nothing to do"
    return 0
  endif

  if !b:differ.IsMergeDiff()
    echomsg "Linediff buffer not generated from :LinediffMerge, nothing to do"
    return 0
  endif

  call b:differ.ReplaceMerge()
  call s:LinediffReset()
endfunction

function! s:FindMergeMarkers()
  let view = winsaveview()

  if search('^<<<<<<<', 'cbW') <= 0
    return []
  endif
  let start_marker = line('.')
  call winrestview(view)

  if search('^>>>>>>>', 'cW') <= 0
    return []
  endif
  let end_marker = line('.')

  if search('^=======', 'cbW') <= 0
    return []
  endif
  let middle_marker = line('.')

  return [
        \   [start_marker + 1, middle_marker - 1],
        \   [middle_marker + 1, end_marker - 1],
        \ ]
endfunction

command! -bang LinediffReset call s:LinediffReset(<q-bang>)
function! s:LinediffReset(bang)
  if s:IsInitialized()
    let force = a:bang == '!'
    call s:differ_one.CloseAndReset(force)
    call s:differ_two.CloseAndReset(force)
  endif
endfunction

" Checks whether plugin is initialized.
function! s:IsInitialized()
  return exists('s:differ_one')
endfunction

" The closing logic is a bit roundabout, since changing a buffer in a
" BufUnload autocommand doesn't seem to work.
"
" The process is: if a window is entered after the other differ was destroyed,
" destroy this one as well and close the window.
"
function! s:PerformDiff()
  call s:differ_one.CreateDiffBuffer(g:linediff_first_buffer_command)
  autocmd BufUnload <buffer> silent call s:differ_one.Reset()
  autocmd WinEnter <buffer> if s:differ_two.IsBlank() | silent call s:differ_one.CloseAndReset(0) | endif

  call s:differ_two.CreateDiffBuffer(g:linediff_second_buffer_command)
  autocmd BufUnload <buffer> silent call s:differ_two.Reset()
  autocmd WinEnter <buffer> if s:differ_one.IsBlank() | silent call s:differ_two.CloseAndReset(0) | endif

  wincmd t " move to the first diff buffer

  let s:differ_one.other_differ = s:differ_two
  let s:differ_two.other_differ = s:differ_one
endfunction

let &cpo = s:keepcpo
