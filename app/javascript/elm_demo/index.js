import { Elm } from './Main.elm';

$(document).ready(() => {
  var node = document.getElementById('main');
  var app = Elm.Main.init({node: node});

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
