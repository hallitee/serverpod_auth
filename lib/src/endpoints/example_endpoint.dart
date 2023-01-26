import 'dart:ffi';
import 'dart:math';

import 'package:auth_example_server/src/generated/example.dart';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

// This is an example endpoint of your server. It's best practice to use the
// `Endpoint` ending of the class name, but it will be removed when accessing
// the endpoint from the client. I.e., this endpoint can be accessed through
// `client.example` on the client side.
const exChannel = "myNumMessages";

String generateRandomString(int len) {
  var r = Random();
  return String.fromCharCodes(
      List.generate(len, (index) => r.nextInt(33) + 89));
}

// After adding or modifying an endpoint, you will need to run
// `serverpod generate` to update the server and client code.
class ExampleEndpoint extends Endpoint {
  @override
  Future<void> streamOpened(StreamingSession session) async {
    int? userId = await session.auth.authenticatedUserId;

    if (userId == 2) {
      session.log("User ID: ${userId!.toString()}");
      session.messages.addListener(exChannel, (message) {
        sendStreamMessage(session, message);
      });
    }

    session.messages.addListener(
        'user_${await session.auth.authenticatedUserId}', (message) {
      sendStreamMessage(session, message);
    });
  }

  @override
  Future<void> handleStreamMessage(
      StreamingSession session, SerializableEntity message) async {
    if (message is Example) {
      session.log("Received Example message ${message.data.toString()}");
      // sendStreamMessage(session, message);
      for (int x = 0; x < 20; x++) {
        await Future.delayed(Duration(seconds: 1));
        message.data = Random().nextInt(100) + 50;
        message.name = generateRandomString(6);
        session.log("Name: ${message.name} Data: ${message.data}",
            level: LogLevel.info);
        session.messages.postMessage(exChannel, message);
        session.messages.postMessage(
            'user_${await session.auth.authenticatedUserId}', message);
      }
    }
    // session.messages.postMessage("myNumMessage", message);
  }

  // You create methods in your endpoint which are accessible from the client by
  // creating a public method with `Session` as its first parameter. Supported
  // parameter types are `bool`, `int`, `double`, `String`, `DateTime`, and any
  // objects that are generated from your `protocol` directory. The methods
  // should return a typed future; the same types as for the parameters are
  // supported. The `session` object provides access to the database, logging,
  // passwords, and information about the request being made to the server.
  Future<String> hello(Session session, String name) async {
    return 'Hello $name';
  }

  Stream<int> numberStream(Session session, int limit) async* {
    for (int i = 0; i < limit; i++) {
      Future.delayed(Duration(seconds: 1));
      yield i;
    }
  }

  // Future<int> numberStream(Session session, int limit) async {
  // return  Stream<int> number() async* {
  //     yield limit;
  //   }
  // }
}
