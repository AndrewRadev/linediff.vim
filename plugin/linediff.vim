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

if !exists('g:linediff_diffopt')
  let g:linediff_diffopt = 'builtin'
endif

command! -range Linediff      call linediff#Linediff(<line1>, <line2>)
command! -bang  LinediffReset call linediff#LinediffReset(<q-bang>)

let &cpo = s:keepcpo
