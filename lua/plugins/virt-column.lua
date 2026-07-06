return {
  {
    'lukas-reineke/virt-column.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      char = '│',
      virtcolumn = '80,120',
      highlight = { 'VirtColumn80', 'VirtColumn120' },
    },
  },
}
