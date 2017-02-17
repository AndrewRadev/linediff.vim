require 'spec_helper'

describe "Multiple lines" do
  let(:filename) { 'test.txt' }

  before do
    set_file_contents <<~EOF
      one
      two
    EOF

    vim.command '1,1Linediff'
    vim.command '2,2Linediff'
  end

  specify "update first buffer" do
    vim.normal 'o---<cr>change<cr>---'
    vim.write

    vim.command 'LinediffReset'

    expect(buffer_contents).to eq <<~EOF
      one
      ---
      change
      ---
      two
    EOF
  end

  specify "update second buffer" do
    wincmd 'w'
    vim.normal 'o---<cr>change<cr>---'
    vim.write

    vim.command 'LinediffReset'

    expect(buffer_contents).to eq <<~EOF
      one
      two
      ---
      change
      ---
    EOF
  end
end
