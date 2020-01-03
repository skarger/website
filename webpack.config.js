const path = require("path");
const HtmlWebpackPlugin = require('html-webpack-plugin');

module.exports = {
  entry: {
    app: './src/web/index.js',
  },
  mode: "development",
  output: {
    filename: '[name].bundle.js',
    path: path.resolve(__dirname, "static/dist"),
  },
  plugins: [
    new HtmlWebpackPlugin({
      title: 'Output Management',
    }),
  ],
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
