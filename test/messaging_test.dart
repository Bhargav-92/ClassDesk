import 'package:class_desk/features/messaging/whatsapp_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('WhatsApp links normalize Indian numbers and encode multiline text', () {
    const text = '*Maths*\nBalance: ₹250 & fees?';
    final link = whatsappUri('+91 98765-43210', text)!;

    expect(link.host, 'wa.me');
    expect(link.path, '/919876543210');
    expect(link.queryParameters['text'], text);
    expect(whatsappUri('9876543210', text), link);
    expect(whatsappUri('1234', text), isNull);
  });

  test('message variables are substituted once', () {
    expect(
      renderMessage('Hello {parent_name}, {student_name} owes ₹{remaining}.', {
        'parent_name': 'Dev',
        'student_name': 'Riya',
        'remaining': '1500',
      }),
      'Hello Dev, Riya owes ₹1500.',
    );
  });
}
