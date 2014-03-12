part of vertx.eventbus.tests;

class MockClient {
  StreamController _onOpenController = new StreamController.broadcast();
  Stream get onOpen => _onOpenController.stream;

  StreamController _onMessageController = new StreamController.broadcast();
  Stream get onMessage => _onMessageController.stream;

  StreamController _onCloseController = new StreamController.broadcast();
  Stream get onClose => _onCloseController.stream;

  var lastSend;

  send(data) {
    lastSend = data;
    return true;
  }

  fakeData({ body: 'body',  replyAddress: 'replyAddr', address: 'address', Map extra : null}) {
    var data = { 'body': body,  'replyAddress': replyAddress, 'address': address};
    if (extra != null) {
      extra.forEach((k,v) => data[k] = v);
    }
    
    sockjs.MessageEvent evt = new sockjs.MessageEvent(JSON.encode(data));
    _onMessageController.add(evt);
  }
}
