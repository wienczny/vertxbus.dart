part of vertx.eventbus;

class EventBusMessageEvent {
  EventBus _eventBus;
  var _body;
  String _replyAddress;

  EventBus get eventBus => _eventBus;
  String get replyAddress => _replyAddress;
  get body => _body;

  EventBusMessageEvent(this._eventBus, this._body, [this._replyAddress]);

  bool canReply() => replyAddress != null && !replyAddress.isEmpty;

  void reply(message, replyHandler) {
    if (canReply()) {
      eventBus.send(replyAddress, message);
    } else {
      //TODO: Throw error
    }
  }
}
