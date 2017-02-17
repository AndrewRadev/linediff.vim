require 'spec_helper'

describe "Basic" do
  let(:filename) { 'test.rb' }

  before do
    set_file_contents <<~EOF
      def one
        "foo"
      end

      def two
        "foo"
      end
    EOF

    vim.command '1,3Linediff'
    vim.command '5,7Linediff'
  end

  specify "two buffers with the diffed areas" do
    expect(buffer_contents).to eq <<~EOF
      def one
        "foo"
      end
    EOF

    wincmd 'w'

    expect(buffer_contents).to eq <<~EOF
      def two
        "foo"
      end
    EOF
  end

  specify "update first buffer" do
    vim.search 'foo'
    vim.normal 'cwbar'
    vim.write

    vim.command 'LinediffReset'

    expect(buffer_contents).to eq <<~EOF
      def one
        "bar"
      end

      def two
        "foo"
      end
    EOF
  end

  specify "update second buffer" do
    wincmd 'w'
    vim.search 'foo'
    vim.normal 'cwbar'
    vim.write

    vim.command 'LinediffReset'

    expect(buffer_contents).to eq <<~EOF
      def one
        "foo"
      end

      def two
        "bar"
      end
    EOF
  end
end
