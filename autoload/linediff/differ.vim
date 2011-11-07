" Constructs a Differ object that is still unbound. To initialize the object
" with data, `Init(from, to)` needs to be invoked on that object.
function! linediff#differ#New(sign_name, sign_number)
  let differ = {
        \ 'original_buffer': -1,
        \ 'diff_buffer':     -1,
        \ 'filetype':        '',
        \ 'from':            -1,
        \ 'to':              -1,
        \ 'sign_name':       a:sign_name,
        \ 'sign_number':     a:sign_number,
        \ 'sign_text':       a:sign_number.'-',
        \ 'is_blank':        1,
        \ 'other_differ':    {},
        \
        \ 'Init':                      function('linediff#differ#Init'),
        \ 'IsBlank':                   function('linediff#differ#IsBlank'),
        \ 'Reset':                     function('linediff#differ#Reset'),
        \ 'Lines':                     function('linediff#differ#Lines'),
        \ 'CreateDiffBuffer':          function('linediff#differ#CreateDiffBuffer'),
        \ 'SetupDiffBuffer':           function('linediff#differ#SetupDiffBuffer'),
        \ 'CloseDiffBuffer':           function('linediff#differ#CloseDiffBuffer'),
        \ 'UpdateOriginalBuffer':      function('linediff#differ#UpdateOriginalBuffer'),
        \ 'PossiblyUpdateOtherDiffer': function('linediff#differ#PossiblyUpdateOtherDiffer'),
        \ 'SetupSigns':                function('linediff#differ#SetupSigns')
        \ }

  exe "sign define ".differ.sign_name." text=".differ.sign_text." texthl=Search"

  return differ
endfunction

" Sets up the Differ with data from the argument list and from the current
" file.
function! linediff#differ#Init(from, to) dict
  let self.original_buffer = bufnr('%')
  let self.filetype        = &filetype
  let self.from            = a:from
  let self.to              = a:to

  call self.SetupSigns()

  let self.is_blank = 0
endfunction

" Returns true if the differ is blank, which means not initialized with data.
function! linediff#differ#IsBlank() dict
  return self.is_blank
endfunction

" Resets the differ to the blank state. Invoke `Init(from, to)` on it later to
" make it usable again.
function! linediff#differ#Reset() dict
  call self.CloseDiffBuffer()

  let self.original_buffer = -1
  let self.diff_buffer     = -1
  let self.filetype        = ''
  let self.from            = -1
  let self.to              = -1
  let self.other_differ    = {}

  exe "sign unplace ".self.sign_number."1"
  exe "sign unplace ".self.sign_number."2"

  let self.is_blank = 1
endfunction

" Extracts the relevant lines from the original buffer and returns them as a
" list.
function! linediff#differ#Lines() dict
  return getbufline(self.original_buffer, self.from, self.to)
endfunction

" Creates the buffer used for the diffing and connects it to this differ
" object.
function! linediff#differ#CreateDiffBuffer(edit_command) dict
  let lines     = self.Lines()
  let temp_file = tempname()

  exe a:edit_command . " " . temp_file
  call append(0, lines)
  normal! Gdd
  set nomodified

  let self.diff_buffer = bufnr('%')
  call self.SetupDiffBuffer()

  diffthis
endfunction

" Sets up the temporary buffer's filetype and statusline.
"
" Attempts to leave the current statusline as it is, and simply add the
" relevant information in the place of the current filename. If that fails,
" replaces the whole statusline.
function! linediff#differ#SetupDiffBuffer() dict
  let b:differ = self

  let statusline = printf('[%s:%%{b:differ.from}-%%{b:differ.to}]', bufname(self.original_buffer))
  if &statusline =~ '%[fF]'
    let statusline = substitute(&statusline, '%[fF]', statusline, '')
  endif
  exe "setlocal statusline=" . escape(statusline, ' |')
  exe "set filetype=" . self.filetype
  setlocal bufhidden=hide

  autocmd BufWrite <buffer> silent call b:differ.UpdateOriginalBuffer()
endfunction

function! linediff#differ#CloseDiffBuffer() dict
  if bufexists(self.diff_buffer)
    exe "bdelete ".self.diff_buffer
  endif
endfunction

function! linediff#differ#SetupSigns() dict
  exe "sign unplace ".self.sign_number."1"
  exe "sign unplace ".self.sign_number."2"

  exe printf("sign place %d1 name=%s line=%d buffer=%d", self.sign_number, self.sign_name, self.from, self.original_buffer)
  exe printf("sign place %d2 name=%s line=%d buffer=%d", self.sign_number, self.sign_name, self.to,   self.original_buffer)
endfunction

" Updates the original buffer after saving the temporary one. It might also
" update the other differ's data, provided a few conditions are met. See
" linediff#differ#PossiblyUpdateOtherDiffer() for details.
function! linediff#differ#UpdateOriginalBuffer() dict
  let new_lines = getbufline('%', 0, '$')

  " Switch to the original buffer, delete the relevant lines, add the new
  " ones, switch back to the diff buffer.
  call linediff#util#SwitchBuffer(self.original_buffer)
  let saved_cursor = getpos('.')
  call cursor(self.from, 1)
  exe "normal! ".(self.to - self.from + 1)."dd"
  call append(self.from - 1, new_lines)
  call setpos('.', saved_cursor)
  call linediff#util#SwitchBuffer(self.diff_buffer)

  " Keep the difference in lines to know how to update the other differ if
  " necessary.
  let line_count     = self.to - self.from + 1
  let new_line_count = len(new_lines)

  let self.to = self.from + len(new_lines) - 1
  call self.SetupDiffBuffer()
  call self.SetupSigns()

  call self.PossiblyUpdateOtherDiffer(new_line_count - line_count)
endfunction

" If the other differ originates from the same buffer and it's located below
" this one, we need to update its starting and ending lines, since any change
" would result in a line shift.
"
" a:delta is the change in the number of lines.
function! linediff#differ#PossiblyUpdateOtherDiffer(delta) dict
  let other = self.other_differ

  if self.original_buffer == other.original_buffer
        \ && self.to <= other.from
        \ && a:delta != 0
    let other.from = other.from + a:delta
    let other.to   = other.to   + a:delta

    call other.SetupSigns()
  endif
endfunction
