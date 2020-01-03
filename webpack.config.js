const path = require("path");

module.exports = {
  entry: "./src/web/index.js",
  mode: "development",
  output: {
    filename: "main.js",
    path: path.resolve(__dirname, "static/dist"),
  },
  module: {
    rules: [
      {
        test: /\.css$/,
        use: [
          "style-loader",
          "css-loader",
        ],
      },
    ],
  },
};