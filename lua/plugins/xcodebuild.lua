-- Xcode build integration for Swift development
-- Provides build, test, and project management for Xcode projects
return {
  "wojciech-kulik/xcodebuild.nvim",
  ft = "swift",
  -- dependencies = {
  --   "nvim-telescope/telescope.nvim",
  --   "MunifTanjim/nui.nvim",
  -- },
  config = function()
    require("xcodebuild").setup({
      -- Customize settings here if needed
      -- See: https://github.com/wojciech-kulik/xcodebuild.nvim
    })
  end,
}
