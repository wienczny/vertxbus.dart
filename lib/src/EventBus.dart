part of vertx.eventbus;

class EventBus {
  /**
   * Logger for this class.
   */
  static final _logger = new Logger("vertx.EventBus");
  
  /**
   * Interval after which a new heartbeat is sent.
   */
  static const HEARTBEAT_INTERVAL = const Duration(seconds: 5);

  /**
   * Map of uuid to callback.
   */
  Map _replyCallbacks = new Map<String, Function>();

  /**
   * Sockjs client.
   */
  var _socket;

  /**
   * Current EventBus state.
   */
  var _state = CLOSED;
  get state => _state;

  /**
   * Subscriptions from upstream sockjs.
   */
  StreamSubscription _openSubscription;
  StreamSubscription _messageSubscription;
  StreamSubscription _closeSubscription;

  /**
   * SessionID assigned by login.
   */
  String _sessionID;

  /**
   * Address of AuthManager on Bus
   */
  String authManagerAddress;

  /**
   * Downstream open event handling.
   */
  StreamController<sockjsevent.Event> _onOpenController = new StreamController<sockjsevent.Event>.broadcast();
  Stream<sockjsevent.Event> get onOpen => _onOpenController.stream;

  /**
   * Downstream message event handling.
   */
  StreamController<EventBusMessageEvent> _onMessageController = new StreamController<EventBusMessageEvent>.broadcast();
  Stream<EventBusMessageEvent> get onMessage => _onMessageController.stream;

  /**
   * Downstream close event handling.
   */
  StreamController<sockjsevent.Event> _onCloseController = new StreamController<sockjsevent.Event>.broadcast();
  Stream<sockjsevent.Event> get onClose => _onCloseController.stream;

  /**
   * Time to send heartbeat messages to the server.
   */
  Timer _heartbeatTimer;

  EventBus(url, {devel: false, debug: false, this.authManagerAddress: 'vertx.basicauthmanager.login',
              socket: null, sessionID}) {
    this._sessionID = sessionID;
    if (socket == null) {
      _socket = new sockjs.Client(url, devel: devel, debug: debug);
      _state = CONNECTING;
    } else {
      _socket = socket;
      _state = CONNECTING;
    }
    _openSubscription = _socket.onOpen.listen(_onOpenHandler);
    _messageSubscription = _socket.onMessage.listen(_onMessageHandler);
    _closeSubscription = _socket.onClose.listen(_onCloseHandler);
  }

  /**
   * Called when underlying socket is opened.
   */
  void _onOpenHandler(sockjsevent.Event event) {
    _logger.info('Open ' + event.toString());
    _state = OPEN;
    _heartbeatTimer = new Timer.periodic(HEARTBEAT_INTERVAL, ping);
    ping(_heartbeatTimer);
    _onOpenController.add(event);
  }

  /**
   * Called when underlying socket received a message.
   */
  void _onMessageHandler(sockjs.MessageEvent event) {
    _logger.info("Message " + event.toString());

    var json = JSON.decode(event.data);
    var body = json['body'];
    var replyAddress = json['replyAddress'];
    var address = json['address'];

    var downstreamEvent = new EventBusMessageEvent(this, body, replyAddress);

    var replyCallback = _replyCallbacks.remove(address);
    if (replyCallback != null) {
      // There is a callback for this address
      replyCallback(downstreamEvent);
      return;
    }

    _onMessageController.add(downstreamEvent);
  }

  /**
   * Called when underlying socket is closed.
   */
  void _onCloseHandler(sockjsevent.Event event) {
    _logger.info('Closed +' + event.toString());
    if (_heartbeatTimer != null) {
      _heartbeatTimer.cancel();
    }
    _state = CLOSED;
    _onCloseController.add(event);
  }

  /**
   * Login to 'authmanager' using username and password.
   */
  void loginUsernamePassword(String username, String password, [void replyHandler(BusMessageEvent)]) {
    login({'username': username, 'password': password});
  }

  /**
   * Login to 'authmanager' using credentials.
   */
  void login(credentials, [void replyHandler(BusMessageEvent)]) {
    send(authManagerAddress, credentials, (busMessageEvent) {
      var body = busMessageEvent.body;
      if (body.status == 'ok') {
        _sessionID = body.sessionID;
      }
      if (replyHandler != null) {
        replyHandler(busMessageEvent);
      }
    });
  }

  /**
   * Send a message using this bus.
   */
  void send(address, message, [replyHandler]) {
    _doSend("send", address, message, replyHandler);
  }

  /**
   * Send a ping.
   */
  void ping(Timer timer) {
    _logger.info('Sending ping');
    _socket.send(JSON.encode({ 'type': "ping" }));
  }

  /**
   * Publish a message using this bus.
   */
  void publish (address, message, [replyHandler]) {
    _doSend("publish", address, message, replyHandler);
  }

  /**
   * Internal method to do the sending.
   */
  void _doSend(String type, String address, var message, [void replyCallback(BusMessageEvent)]) {
    var envelope = {
        'type' : type,
        'address' : address,
        'body' : message
    };
    if (_sessionID != null) {
      envelope['sessionID'] = _sessionID;
    }
    if (replyCallback != null) {
      var replyAddress = uuid.v4();
      envelope['replyAddress'] = replyAddress;
      _replyCallbacks[replyAddress] = replyCallback;
    }
    _socket.send(JSON.encode(envelope));
  }
}
