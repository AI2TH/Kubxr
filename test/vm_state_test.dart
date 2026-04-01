import 'package:flutter_test/flutter_test.dart';
import 'package:kubxr/main.dart';

void main() {
  group('VmState', () {
    test('initial status should be stopped', () {
      final vmState = VmState();
      expect(vmState.status, 'stopped');
    });

    test('setStatus should update the status', () {
      final vmState = VmState();
      vmState.setStatus('running');
      expect(vmState.status, 'running');

      vmState.setStatus('paused');
      expect(vmState.status, 'paused');
    });

    test('setStatus should notify listeners', () {
      final vmState = VmState();
      var notificationCount = 0;
      vmState.addListener(() {
        notificationCount++;
      });

      vmState.setStatus('running');
      expect(notificationCount, 1);
      expect(vmState.status, 'running');

      vmState.setStatus('stopped');
      expect(notificationCount, 2);
      expect(vmState.status, 'stopped');
    });
  });
}
