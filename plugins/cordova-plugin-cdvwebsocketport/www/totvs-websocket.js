  function WebSocketPort() {
  }

  WebSocketPort.prototype.getPort = function(successCallBack, errorCallBack) {
    cordova.exec(successCallBack, errorCallBack,"CDVWebSocketPort", "getPort",null);
  }
  
  WebSocketPort.install = function () {
    if (!window.plugins) {
          window.plugins = {};
            }

      window.plugins.websocketport = new WebSocketPort();
        return window.plugins.websocketport;
};

cordova.addConstructor(WebSocketPort.install);