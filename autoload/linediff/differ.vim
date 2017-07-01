" Constructs a Differ object that is still unbound. To initialize the object
" with data, `Init(from, to)` needs to be invoked on that object.
function! linediff#differ#New(sign_name, sign_number)
  let differ = {
        \ 'original_buffer':    -1,
        \ 'original_bufhidden': '',
        \ 'diff_buffer':        -1,
        \ 'index':              -1,
        \ 'filetype':           '',
        \ 'from':               -1,
        \ 'to':                 -1,
        \ 'sign_name':          a:sign_name,
        \ 'sign_number':        a:sign_number,
        \ 'sign_text':          a:sign_number.'-',
        \ 'is_blank':           1,
        \ 'other_differs':      [],
        \ 'is_merge':           0,
        \ 'merge_from':         -1,
        \ 'merge_to':           -1,
        \ 'label':              '',
        \
        \ 'Init':                       function('linediff#differ#Init'),
        \ 'IsBlank':                    function('linediff#differ#IsBlank'),
        \ 'IsMergeDiff':                function('linediff#differ#IsMergeDiff'),
        \ 'Reset':                      function('linediff#differ#Reset'),
        \ 'CloseAndReset':              function('linediff#differ#CloseAndReset'),
        \ 'Lines':                      function('linediff#differ#Lines'),
        \ 'Indent':                     function('linediff#differ#Indent'),
        \ 'CreateDiffBuffer':           function('linediff#differ#CreateDiffBuffer'),
        \ 'SetupDiffBuffer':            function('linediff#differ#SetupDiffBuffer'),
        \ 'SetupUpdateAutocommands':    function('linediff#differ#SetupUpdateAutocommands'),
        \ 'CloseDiffBuffer':            function('linediff#differ#CloseDiffBuffer'),
        \ 'UpdateOriginalBuffer':       function('linediff#differ#UpdateOriginalBuffer'),
        \ 'PossiblyUpdateOtherDiffers': function('linediff#differ#PossiblyUpdateOtherDiffers'),
        \ 'UpdateOtherDiffer':          function('linediff#differ#UpdateOtherDiffer'),
        \ 'SetupSigns':                 function('linediff#differ#SetupSigns'),
        \ 'ReplaceMerge':               function('linediff#differ#ReplaceMerge'),
        \ }

  exe "sign define ".differ.sign_name." text=".differ.sign_text." texthl=Search"

  return differ
endfunction

" Sets up the Differ with data from the argument list and from the current
" file.
function! linediff#differ#Init(from, to, options) dict
  let self.original_buffer    = bufnr('%')
  let self.original_bufhidden = &bufhidden

  let self.filetype = &filetype
  let self.from     = a:from
  let self.to       = a:to

  for k in keys(a:options)
    if has_key(self, k)
      let self[k] = a:options[k]
    endif
  endfor

  call self.SetupSigns()

  set bufhidden=hide

  let self.is_blank = 0
endfunction

" Returns true if the differ is blank, which means not initialized with data.
function! linediff#differ#IsBlank() dict
  return self.is_blank
endfunction

" Resets the differ to the blank state. Invoke `Init(from, to)` on it later to
" make it usable again.
function! linediff#differ#Reset() dict
  call setbufvar(self.original_buffer, '&bufhidden', self.original_bufhidden)

  let self.original_buffer    = -1
  let self.original_bufhidden = ''
  let self.diff_buffer        = -1
  let self.filetype           = ''
  let self.from               = -1
  let self.to                 = -1
  let self.other_differs      = []

  exe "sign unplace ".self.sign_number."1"
  exe "sign unplace ".self.sign_number."2"

  let self.is_blank = 1
  let self.is_merge = 0
  let self.merge_from = -1
  let self.merge_to = -1
  let self.label    = ''

  if exists('g:linediff_original_diffopt')
    let &diffopt = g:linediff_original_diffopt
    unlet g:linediff_original_diffopt
  endif
endfunction

" Closes the diff buffer and resets. The two actions are separate to avoid
" problems with closing already closed buffers.
function! linediff#differ#CloseAndReset(force) dict
  call self.CloseDiffBuffer(a:force)
  call self.Reset()
endfunction

" Extracts the relevant lines from the original buffer and returns them as a
" list.
function! linediff#differ#Lines() dict
  return getbufline(self.original_buffer, self.from, self.to)
endfunction

" Creates the buffer used for the diffing and connects it to this differ
" object.
function! linediff#differ#CreateDiffBuffer(edit_command, index) dict
  let lines = self.Lines()

  if g:linediff_buffer_type == 'tempfile'
    let temp_file = tempname()
    call writefile(lines, temp_file)
    silent exe a:edit_command . " " . temp_file
    normal! gg
  else " g:linediff_buffer_type == 'scratch'
    silent exe a:edit_command

    if v:version > 704 || v:version == 704 && has("patch73")
      setlocal undolevels=-1
    endif

    call append(0, lines)
    silent $delete _

    if v:version > 704 || v:version == 704 && has("patch73")
      setlocal undolevels<
    endif

    setlocal buftype=acwrite
    setlocal bufhidden=wipe
  endif

  let self.diff_buffer = bufnr('%')
  let self.index = a:index
  call self.SetupDiffBuffer()
  call self.SetupUpdateAutocommands()
  call self.Indent()

  diffthis

  if exists('#User#LinediffBufferReady')
    doautocmd User LinediffBufferReady
  endif
endfunction

" Indents the current buffer content so that format can be ignored.
function! linediff#differ#Indent() dict
  if g:linediff_indent
    silent normal! gg=G
  endif
endfunction

" Sets up the temporary buffer's filetype and statusline.
"
" Attempts to leave the current statusline as it is, and simply add the
" relevant information in the place of the current filename. If that fails,
" replaces the whole statusline.
function! linediff#differ#SetupDiffBuffer() dict
  let b:differ = self

  if self.label == ''
    let label = ''
  else
    let label = ' ('.self.label.')'
  endif

  let self.description = printf('[%s:%s-%s%s]',
        \ bufname(self.original_buffer),
        \ self.from,
        \ self.to,
        \ label)

  if g:linediff_buffer_type == 'tempfile'
    if g:linediff_modify_statusline
      if &statusline =~ '%[fF]'
        let statusline = substitute(&statusline, '%[fF]', escape(self.description, '\'), '')
      else
        let statusline = self.description
      endif
      let &l:statusline = statusline
    endif

    exe "set filetype=" . self.filetype
    setlocal bufhidden=wipe
  else " g:linediff_buffer_type == 'scratch'
    silent exec 'keepalt file ' . escape(self.description, '[ ')
    exe "set filetype=" . self.filetype
    set nomodified
  endif
endfunction

" Note: should only be called when the buffer is initialized.
function! linediff#differ#SetupUpdateAutocommands()
  if g:linediff_buffer_type == 'tempfile'
    autocmd BufWrite <buffer> silent call b:differ.UpdateOriginalBuffer()
  else " g:linediff_buffer_type == 'scratch'
    autocmd BufWriteCmd <buffer> silent call b:differ.UpdateOriginalBuffer()
  endif
endfunction

function! linediff#differ#CloseDiffBuffer(force) dict
  if bufexists(self.diff_buffer)
    let bang = a:force ? '!' : ''
    exe "bdelete".bang." ".self.diff_buffer
  endif
endfunction

function! linediff#differ#SetupSigns() dict
  exe "sign unplace ".self.sign_number."1"
  exe "sign unplace ".self.sign_number."2"

  silent! exe printf("sign place %d1 name=%s line=%d buffer=%d",
        \ self.sign_number, self.sign_name, self.from, self.original_buffer)
  silent! exe printf("sign place %d2 name=%s line=%d buffer=%d",
        \ self.sign_number, self.sign_name, self.to, self.original_buffer)
endfunction

" Updates the original buffer after saving the temporary one. It might also
" update the other differ's data, provided a few conditions are met. See
" linediff#differ#PossiblyUpdateOtherDiffer() for details.
function! linediff#differ#UpdateOriginalBuffer() dict
  if self.IsBlank()
    return
  endif

  let saved_diff_buffer_view = winsaveview()
  let new_lines = getbufline('%', 0, '$')

  " Switch to the original buffer, delete the relevant lines, add the new
  " ones, switch back to the diff buffer.
  set bufhidden=hide
  call linediff#util#SwitchBuffer(self.original_buffer)
  call cursor(self.from, 1)
  exe "silent! ".(self.to - self.from + 1)."foldopen!"
  exe "normal! ".(self.to - self.from + 1)."dd"
  call append(self.from - 1, new_lines)
  call linediff#util#SwitchBuffer(self.diff_buffer)
  set bufhidden=wipe

  " Keep the difference in lines to know how to update the other differ if
  " necessary.
  let line_count     = self.to - self.from + 1
  let new_line_count = len(new_lines)

  let self.to = self.from + len(new_lines) - 1
  call self.SetupDiffBuffer()
  call self.SetupSigns()

  call self.PossiblyUpdateOtherDiffers(new_line_count - line_count)
  call winrestview(saved_diff_buffer_view)
endfunction

" If the other differ originates from the same buffer and it's located below
" this one, we need to update its starting and ending lines, since any change
" would result in a line shift.
"
" a:delta is the change in the number of lines.
function! linediff#differ#PossiblyUpdateOtherDiffers(delta) dict
  if a:delta == 0
    return
  endif
  for other in self.other_differs
    call self.UpdateOtherDiffer(a:delta, other)
  endfor
endfunction

function! linediff#differ#UpdateOtherDiffer(delta, other) dict
  if self.original_buffer == a:other.original_buffer
        \ && self.to <= a:other.from
    let a:other.from = a:other.from + a:delta
    let a:other.to   = a:other.to   + a:delta

    call a:other.SetupSigns()
  endif
  if self.is_merge && a:other.is_merge
    let a:other.merge_to = a:other.merge_to + a:delta
  endif
endfunction

" Was this buffer created from a merge area?
function! linediff#differ#IsMergeDiff() dict
  return self.is_merge
endfunction

" Replace the saved merge area with the contents of this buffer
function! linediff#differ#ReplaceMerge() dict
  " Save real buffer range
  let [real_from, real_to] = [self.from, self.to]

  try
    " Set the buffer range to the merge area in order to replace the whole thing
    let self.from = self.merge_from
    let self.to   = self.merge_to

    call self.UpdateOriginalBuffer()
  finally
    " Restore the real buffer range
    let [self.from, self.to] = [real_from, real_to]
  endtry
endfunction
