require 'spec_helper'

describe "Merge conflicts" do
  let(:filename) { 'test.txt' }

  describe "two-way" do
    before do
      set_file_contents <<~EOF
      def one
      <<<<<<< master
        "first"
      =======
        "second"
      >>>>>>> branch
      end
      EOF

      vim.search 'first'
      vim.command 'LinediffMerge'
    end

    specify "change and pick first buffer" do
      vim.normal 'o  "change"'
      vim.write

      vim.command 'LinediffPick'

      expect(buffer_contents).to eq <<~EOF
      def one
        "first"
        "change"
      end
      EOF
    end

    specify "change and pick second buffer" do
      wincmd 'w'
      vim.normal 'o  "change"'
      vim.write

      vim.command 'LinediffPick'

      expect(buffer_contents).to eq <<~EOF
      def one
        "second"
        "change"
      end
      EOF
    end
  end

  describe "three-way" do
    before do
      set_file_contents <<~EOF
      def one
      <<<<<<< master
        "first"
      |||||||
        "second"
      =======
        "third"
      >>>>>>> branch
      end
      EOF

      vim.search 'first'
      vim.command 'LinediffMerge'
    end

    specify "change and pick first buffer" do
      vim.normal 'o  "change"'
      vim.write

      vim.command 'LinediffPick'

      expect(buffer_contents).to eq <<~EOF
        def one
          "first"
          "change"
        end
      EOF
    end

    specify "change and pick second buffer" do
      wincmd 'w'
      vim.normal 'o  "change"'
      vim.write

      vim.command 'LinediffPick'

      expect(buffer_contents).to eq <<~EOF
        def one
          "second"
          "change"
        end
      EOF
    end

    specify "change and pick third buffer" do
      wincmd 'w'
      wincmd 'w'
      vim.normal 'o  "change"'
      vim.write

      vim.command 'LinediffPick'

      expect(buffer_contents).to eq <<~EOF
        def one
          "third"
          "change"
        end
      EOF
    end
  end
end
