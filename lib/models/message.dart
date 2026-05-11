class Message {
  final int? id;
  final int contactId;
  final String body;
  final int isSent; // 1 = sent by me, 0 = received
  final String timestamp;

  Message({
    this.id,
    required this.contactId,
    required this.body,
    required this.isSent,
    required this.timestamp,
  });

  // Convert Message to a Map for SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contact_id': contactId,
      'body': body,
      'is_sent': isSent,
      'timestamp': timestamp,
    };
  }

  // Create a Message from a SQLite Map
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      contactId: map['contact_id'],
      body: map['body'],
      isSent: map['is_sent'],
      timestamp: map['timestamp'],
    );
  }
}