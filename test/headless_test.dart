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
      bus.onMessage.listen(expectAsync((event) => expect( event.body, equals('body'))));
      client.fakeData();
    });
    
    test("send callback" , () {
      bus.send('address', {'data': 'data'}, expectAsync((event) => expect( event.body, equals('body2') )));
  
      expect(client.lastSend, isNotNull);
  
      var lastMessage = JSON.decode(client.lastSend);
  
      client.fakeData(body: 'body2', address: lastMessage['replyAddress']);
    });
    
    test("send callback after listen", () {
      bus.onMessage.listen(expectAsync((event) => expect( event.body, equals('body'))));
      client.fakeData();

      bus.send('address', {'data': 'data'}, expectAsync((event) => expect( event.body, equals('body2') )));
      
      expect(client.lastSend, isNotNull);
  
      var lastMessage = JSON.decode(client.lastSend);
  
      client.fakeData(body: 'body2', address: lastMessage['replyAddress']);      
    });
    
    test("register and receive", () {
      bus.registerHandler('testAddress', expectAsync((event) => expect( event.body, equals('body'))));
      client.fakeData(address: 'testAddress');
    });

    test("onSessionIdChanged", () {
      bus.onSessionIdChanged.listen(expectAsync((event) => expect( event, equals('mySession1'))));
      bus.sessionID = 'mySession1';
    });
    
    test("login", () {
      var body = {'status': 'ok', 'sessionID' : 'mySession2'};
      bus.onSessionIdChanged.listen(expectAsync((event) => expect( event, equals('mySession2'))));

      bus.loginUsernamePassword("username", "password", expectAsync((event) => expect( event.body, equals(body))));

      var lastMessage = JSON.decode(client.lastSend);

      client.fakeData(body: body, address: lastMessage['replyAddress']);      
    });

  });
}