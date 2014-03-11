part of vertx.eventbus;

class EventBusMessageEvent {
  final EventBus eventBus;
  final body;
  final String replyAddress;

  EventBusMessageEvent(this.eventBus, this.body, [this.replyAddress]);

  bool canReply() => replyAddress != null && !replyAddress.isEmpty;

  void reply(message, [void replyCallback(EventBusMessageEvent)]) {
    if (canReply()) {
      eventBus.send(replyAddress, message, replyCallback);
    } else {
      //TODO: Throw error
    }
  }
}
