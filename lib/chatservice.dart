final _instance = ChatService();

class ChatService {
  static get instance => _instance;

  Stream<List<String>> getMessages() {
    return Stream.fromIterable([
      ['hello!']
    ]);
  }
}
