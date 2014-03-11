library vertx.eventbus.tests;

import 'dart:async';
import 'dart:convert';

import 'package:unittest/unittest.dart';
import 'package:logging/logging.dart';
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:unittest/html_enhanced_config.dart';
import 'package:sockjs_client/sockjs.dart' as sockjs;

import '../lib/vertxbus.dart';

part 'mocks/mockclient.dart';

void main() {
  Logger.root.onRecord.listen(new LogPrintHandler());
  useHtmlEnhancedConfiguration();

  MockClient client;
  EventBus bus;

  group('EventBus', (){
    setUp(() {
      client = new MockClient();
      bus = new EventBus("", socket:  client);    
    });
    
    test("listen", () {
      bus.onMessage.listen(expectAsync1((event) => expect( event.body, equals('body'))));
      client.fakeData();
    });
    
    test("send callback" , () {
      bus.send('address', {'data': 'data'}, expectAsync1((event) => expect( event.body, equals('body2') )));
  
      expect(client.lastSend, isNotNull);
  
      var lastMessage = JSON.decode(client.lastSend);
  
      client.fakeData(body: 'body2', address: lastMessage['replyAddress']);
    });
    
    test("send callback after listen", () {
      bus.onMessage.listen(expectAsync1((event) => expect( event.body, equals('body'))));
      client.fakeData();

      bus.send('address', {'data': 'data'}, expectAsync1((event) => expect( event.body, equals('body2') )));
      
      expect(client.lastSend, isNotNull);
  
      var lastMessage = JSON.decode(client.lastSend);
  
      client.fakeData(body: 'body2', address: lastMessage['replyAddress']);      
    });
  });
}