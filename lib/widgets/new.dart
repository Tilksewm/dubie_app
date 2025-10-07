import 'package:dubie_app/models/comment.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting

// 2. ChatMessageWidget
class ChatMessageWidget extends StatelessWidget {
  final Comment message;
  final String currentUserId; // ID of the currently logged-in user

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = message.userId == currentUserId;
    final Alignment messageAlignment =
    isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
    final Color bubbleColor =
    isCurrentUser ? Colors.blue[600]! : Colors.grey[300]!;
    final Color textColor = isCurrentUser ? Colors.white : Colors.black87;
    final CrossAxisAlignment crossAxisAlignment =
    isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final Radius bubbleRadiusCurrentUser = Radius.circular(16.0);
    final Radius bubbleRadiusOtherUser = Radius.circular(16.0);

    return Align(
      alignment: messageAlignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: isCurrentUser ? bubbleRadiusCurrentUser : Radius.zero,
            topRight: isCurrentUser ? Radius.zero : bubbleRadiusOtherUser,
            bottomLeft: bubbleRadiusCurrentUser,
            bottomRight: bubbleRadiusOtherUser,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 1,
              offset: Offset(0, 1),
            )
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery
              .of(context)
              .size
              .width * 0.75, // Max bubble width
        ),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          // Text alignment within the bubble
          mainAxisSize: MainAxisSize.min,
          // Bubble takes minimum necessary vertical space
          children: [
            Text(
              message.commentText,
              style: TextStyle(color: textColor, fontSize: 16.0),
            ),
            const SizedBox(height: 4.0),
            Text(
              DateFormat('hh:mm a yyyy-MM-dd').format(DateTime.parse(message.createdAt)),
              // Example: 10:30 AM
              style: TextStyle(
                color: isCurrentUser ? Colors.white70 : Colors.black54,
                fontSize: 10.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
//
// // --- Example Usage ---
// class ChatScreenExample extends StatefulWidget {
//   const ChatScreenExample({super.key});
//
//   @override
//   State<ChatScreenExample> createState() => _ChatScreenExampleState();
// }
//
// class _ChatScreenExampleState extends State<ChatScreenExample> {
//   final String _currentUserId = 'user123'; // Simulate current user
//   final String _otherUserId = 'friend456'; // Simulate other user
//
//   final List<Comment> _messages = [];
//
//   //final TextEditingController _textController = TextEditingController();
//   // final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     // Sample messages
//     _messages.addAll([
//       ChatMessageModel(
//           id: '1',
//           text: 'Hey there!',
//           senderId: _currentUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
//       ChatMessageModel(
//           id: '2',
//           text: 'Hi! How are you doing?',
//           senderId: _otherUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 4))),
//       ChatMessageModel(
//           id: '3',
//           text: 'Doing great! Just working on this chat UI. 😊',
//           senderId: _currentUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 3))),
//       ChatMessageModel(
//           id: '4',
//           text: 'Oh cool! Looks good so far. Keep it up!',
//           senderId: _otherUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
//       ChatMessageModel(
//           id: '5',
//           text:
//           'Thanks! This is a longer message to see how the text wrapping and bubble sizing behaves. It should adjust nicely.',
//           senderId: _currentUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 1))),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _otherUserId,
//           timestamp: DateTime.now()),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _otherUserId,
//           timestamp: DateTime.now()),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _otherUserId,
//           timestamp: DateTime.now()),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _currentUserId,
//           timestamp: DateTime.now()),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _currentUserId,
//           timestamp: DateTime.now()),
//     ]);
//   }

  // // void _sendMessage() {
  // //   if (_textController.text
  // //       .trim()
  // //       .isEmpty) return;
  // //
  // //   final newMessage = ChatMessageModel(
  // //     id: DateTime
  // //         .now()
  // //         .millisecondsSinceEpoch
  // //         .toString(), // Simple unique ID
  // //     text: _textController.text.trim(),
  // //     senderId: _currentUserId,
  // //     timestamp: DateTime.now(),
  // //   );
  //
  //   setState(() {
  //     _messages.add(newMessage);
  //     _textController.clear();
  //   });

  // Scroll to the bottom after sending a message
  // WidgetsBinding.instance.addPostFrameCallback((_) {
  //   if (_scrollController.hasClients) {
  //     _scrollController.animateTo(
  //       _scrollController.position.maxScrollExtent,
  //       duration: const Duration(milliseconds: 300),
  //       curve: Curves.easeOut,
  //     );
  //   }
  // });
  //}
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   title: const Text('Chat UI'),
//       // ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               //controller: _scrollController,
//               padding: const EdgeInsets.all(8.0),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final message = _messages[index];
//                 return ChatMessageWidget(
//                   message: message,
//                   currentUserId: _currentUserId,
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
// To run this example:
// void main() {
//   runApp(MaterialApp(
//     theme: ThemeData.light(useMaterial3: true),
//     darkTheme: ThemeData.dark(useMaterial3: true),
//     home: ChatScreenExample(),
//   ));
// }
//
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart'; // For date formatting
//
// // 1. ChatMessageModel
// class ChatMessageModel {
//   final String id; // Unique message ID
//   final String text;
//   final String senderId; // ID of the user who sent the message
//   final DateTime timestamp;
//
//   ChatMessageModel({
//     required this.id,
//     required this.text,
//     required this.senderId,
//     required this.timestamp,
//   });
// }
//
// // 2. ChatMessageWidget
// class ChatMessageWidget extends StatelessWidget {
//   final ChatMessageModel message;
//   final String currentUserId; // ID of the currently logged-in user
//
//   const ChatMessageWidget({
//     Key? key,
//     required this.message,
//     required this.currentUserId,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isCurrentUser = message.senderId == currentUserId;
//     final Alignment messageAlignment =
//     isCurrentUser ? Alignment.centerRight : Alignment.centerLeft;
//     final Color bubbleColor =
//     isCurrentUser ? Colors.blue[600]! : Colors.grey[300]!;
//     final Color textColor = isCurrentUser ? Colors.white : Colors.black87;
//     final CrossAxisAlignment crossAxisAlignment =
//     isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
//     final Radius bubbleRadiusCurrentUser = Radius.circular(16.0);
//     final Radius bubbleRadiusOtherUser = Radius.circular(16.0);
//
//     return Align(
//       alignment: messageAlignment,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
//         padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
//         decoration: BoxDecoration(
//           color: bubbleColor,
//           borderRadius: BorderRadius.only(
//             topLeft: isCurrentUser ? bubbleRadiusCurrentUser : Radius.zero,
//             topRight: isCurrentUser ? Radius.zero : bubbleRadiusOtherUser,
//             bottomLeft: bubbleRadiusCurrentUser,
//             bottomRight: bubbleRadiusOtherUser,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.05),
//               spreadRadius: 1,
//               blurRadius: 1,
//               offset: Offset(0, 1),
//             )
//           ],
//         ),
//         constraints: BoxConstraints(
//           maxWidth: MediaQuery
//               .of(context)
//               .size
//               .width * 0.75, // Max bubble width
//         ),
//         child: Column(
//           crossAxisAlignment: crossAxisAlignment,
//           // Text alignment within the bubble
//           mainAxisSize: MainAxisSize.min,
//           // Bubble takes minimum necessary vertical space
//           children: [
//             Text(
//               message.text,
//               style: TextStyle(color: textColor, fontSize: 16.0),
//             ),
//             const SizedBox(height: 4.0),
//             Text(
//               DateFormat('hh:mm a').format(message.timestamp),
//               // Example: 10:30 AM
//               style: TextStyle(
//                 color: isCurrentUser ? Colors.white70 : Colors.black54,
//                 fontSize: 10.0,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // --- Example Usage ---
// class ChatScreenExample extends StatefulWidget {
//   const ChatScreenExample({super.key});
//
//   @override
//   State<ChatScreenExample> createState() => _ChatScreenExampleState();
// }
//
// class _ChatScreenExampleState extends State<ChatScreenExample> {
//   final String _currentUserId = 'user123'; // Simulate current user
//   final String _otherUserId = 'friend456'; // Simulate other user
//
//   final List<ChatMessageModel> _messages = [];
//   final TextEditingController _textController = TextEditingController();
//   // final ScrollController _scrollController = ScrollController();
//
//   @override
//   void initState() {
//     super.initState();
//     // Sample messages
//     _messages.addAll([
//       ChatMessageModel(
//           id: '1',
//           text: 'Hey there!',
//           senderId: _currentUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
//       ChatMessageModel(
//           id: '2',
//           text: 'Hi! How are you doing?',
//           senderId: _otherUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 4))),
//       ChatMessageModel(
//           id: '3',
//           text: 'Doing great! Just working on this chat UI. 😊',
//           senderId: _currentUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 3))),
//       ChatMessageModel(
//           id: '4',
//           text: 'Oh cool! Looks good so far. Keep it up!',
//           senderId: _otherUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
//       ChatMessageModel(
//           id: '5',
//           text:
//           'Thanks! This is a longer message to see how the text wrapping and bubble sizing behaves. It should adjust nicely.',
//           senderId: _currentUserId,
//           timestamp: DateTime.now().subtract(const Duration(minutes: 1))),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _otherUserId,
//           timestamp: DateTime.now()),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _otherUserId,
//           timestamp: DateTime.now()),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _otherUserId,
//           timestamp: DateTime.now()),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _currentUserId,
//           timestamp: DateTime.now()),
//       ChatMessageModel(
//           id: '6',
//           text: 'Indeed it does. Very nice work!',
//           senderId: _currentUserId,
//           timestamp: DateTime.now()),
//     ]);
//   }
//
//   void _sendMessage() {
//     if (_textController.text
//         .trim()
//         .isEmpty) return;
//
//     final newMessage = ChatMessageModel(
//       id: DateTime
//           .now()
//           .millisecondsSinceEpoch
//           .toString(), // Simple unique ID
//       text: _textController.text.trim(),
//       senderId: _currentUserId,
//       timestamp: DateTime.now(),
//     );
//
//     setState(() {
//       _messages.add(newMessage);
//       _textController.clear();
//     });
//
//     // Scroll to the bottom after sending a message
//     // WidgetsBinding.instance.addPostFrameCallback((_) {
//     //   if (_scrollController.hasClients) {
//     //     _scrollController.animateTo(
//     //       _scrollController.position.maxScrollExtent,
//     //       duration: const Duration(milliseconds: 300),
//     //       curve: Curves.easeOut,
//     //     );
//     //   }
//     // });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       // appBar: AppBar(
//       //   title: const Text('Chat UI'),
//       // ),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               //controller: _scrollController,
//               padding: const EdgeInsets.all(8.0),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final message = _messages[index];
//                 return ChatMessageWidget(
//                   message: message,
//                   currentUserId: _currentUserId,
//                 );
//               },
//             ),
//           ),
//           _buildMessageComposer(),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildMessageComposer() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
//       decoration: BoxDecoration(
//         color: Theme
//             .of(context)
//             .cardColor,
//         boxShadow: [
//           BoxShadow(
//             offset: const Offset(0, -1),
//             blurRadius: 1,
//             color: Colors.black.withOpacity(0.1),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _textController,
//               decoration: InputDecoration(
//                 hintText: 'Type a message...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(20.0),
//                   borderSide: BorderSide.none,
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[200],
//                 contentPadding:
//                 const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
//               ),
//               onSubmitted: (_) => _sendMessage(),
//               minLines: 1,
//               maxLines: 5, // Allow multiline input
//             ),
//           ),
//           const SizedBox(width: 8.0),
//           IconButton(
//             icon: Icon(Icons.send, color: Theme
//                 .of(context)
//                 .primaryColor),
//             onPressed: _sendMessage,
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _textController.dispose();
//     //_scrollController.dispose();
//     super.dispose();
//   }
// }
//
// // To run this example:
// // void main() {
// //   runApp(MaterialApp(
// //     theme: ThemeData.light(useMaterial3: true),
// //     darkTheme: ThemeData.dark(useMaterial3: true),
// //     home: ChatScreenExample(),
// //   ));
// // }
