import App from './src/Main'

$(document).ready(() => {
  var node = document.getElementById('main');
  var app = App.Main.embed(node);
});
