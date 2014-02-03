import 'dart:async';
import 'dart:convert';

import 'package:unittest/unittest.dart';
import 'package:sockjs_client/sockjs.dart' as sockjs;

import '../lib/vertxbus.dart';

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

  fakeData({ body: 'body',  replyAddress: 'replyAddr', address: 'address'}) {
    var data = { 'body': body,  'replyAddress': replyAddress, 'address': address};
    sockjs.MessageEvent evt = new sockjs.MessageEvent(JSON.encode(data));
    _onMessageController.add(evt);
  }
}

void main() {

  test("eventbus generation and events", () {
    MockClient client = new MockClient();
    
    EventBus bus = new EventBus("", socket:  client);
    
    bus.onMessage.listen(expectAsync1((event) => expect( event.body, equals('body'))));

    client.fakeData();
    bus.send('address', {'data': 'data'}, expectAsync1((event) => expect( event.body, equals('body2') )));

    expect(client.lastSend, isNotNull);

    var lastMessage = JSON.decode(client.lastSend);

    client.fakeData(body: 'body2', address: lastMessage['replyAddress']);
  });
}