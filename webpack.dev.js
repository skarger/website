const merge = require('webpack-merge');
const common = require('./webpack.common.js');

module.exports = merge(common, {
  mode: "development",
  devtool: "inline-source-map",
  devServer: {
    contentBase: './static/dist',
    writeToDisk: true, // make updated files available to backend server
    port: 8081, // avoid conflict with backend server
  },
});
