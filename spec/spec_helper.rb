require 'vimrunner'
require 'vimrunner/rspec'
require_relative './support/vim'

Vimrunner::RSpec.configure do |config|
  config.reuse_server = true

  plugin_path = File.expand_path('.')

  config.start_vim do
    vim = Vimrunner.start_gvim
    vim.add_plugin(plugin_path, 'plugin/linediff.vim')
    vim
  end
end

RSpec.configure do |config|
  config.include Support::Vim

  config.after :each do
    vim.command 'wall'
    vim.command 'tabnew'
    vim.command 'tabonly'
  end
end
