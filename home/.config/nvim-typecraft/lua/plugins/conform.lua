return {
  {
    "stevearc/conform.nvim",
    opts = {
      timeout = 1000,
      formatters_by_ft = {
        python = { "isort", "black" },
        quarto = { "injected" },
        markdown = { "markdownlint-cli2", "injected" },
        r = { "air" },
        ["*"] = { "injected" },
      },
      formatters = {
        ["markdownlint-cli2"] = {
          args = { "$FILENAME", "--fix" },
        },
        injected = {
          options = {
            -- Set to true to ignore errors
            ignore_errors = false,
            -- Map of treesitter language to file extension
            -- A temporary file name with this extension will be generated during formatting
            -- because some formatters care about the filename.
            lang_to_ext = {
              bash = "sh",
              c_sharp = "cs",
              elixir = "exs",
              javascript = "js",
              julia = "jl",
              latex = "tex",
              markdown = "md",
              python = "py",
              ruby = "rb",
              rust = "rs",
              teal = "tl",
              r = "r",
              typescript = "ts",
            },
            -- Map of treesitter language to formatters to use
            -- (defaults to the value from formatters_by_ft)
            lang_to_formatters = {},
          },
        },
      },
    },
  },
}
