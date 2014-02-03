library vertx.eventbus;

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';
import 'package:sockjs_client/sockjs.dart' as sockjs;
import 'package:sockjs_client/src/events.dart' as sockjsevent;

part './src/EventBusMessageEvent.dart';
part './src/EventBus.dart';

const CONNECTING = 0;
const OPEN = 1;
const CLOSING = 2;
const CLOSED = 3;

var uuid = new Uuid();

