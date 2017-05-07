import App from './Main'

$(document).ready(() => {
  var node = document.getElementById('main');
  var app = App.Main.embed(node);

  app.ports.highlightCode.subscribe(function(options) {
    var highlightPoller = setInterval(function() {
      hljs.initHighlighting.called = false;
      hljs.initHighlighting();

      // no need to keep checking if highlighting complete
      var codeBlocks = $('code');
      var highlightedCodeBlocks = $('code.hljs');
      if (codeBlocks.length > 0 &&
          (highlightedCodeBlocks.length >= codeBlocks.length) )
      {
        clearInterval(highlightPoller);
      }
    }, 100)
  });
})
