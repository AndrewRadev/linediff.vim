# Ad-hoc test script for :LinediffReset. Needs Vimrunner.

require 'vimrunner'

vim = Vimrunner.start_gvim
vim.add_plugin(File.expand_path('.'), 'plugin/linediff.vim')
vim.command('source ~/.vim/plugin/cecutil.vim')
vim.command('source ~/.vim/plugin/Decho.vim')

vim.edit('example/one.rb')
vim.normal('Vjj:Linediff<cr>')
vim.command('5')
vim.normal('Vjj:Linediff<cr>')
sleep 0.5
vim.command('LinediffReset')
