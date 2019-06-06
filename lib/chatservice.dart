class ChatService {
  Stream<List<String>> getMessages() {
    return Stream.fromIterable([
      ['hello!']
    ]);
  }
}
