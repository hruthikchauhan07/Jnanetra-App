import '../ml/detection.dart';

class DecisionEngine {
  NavigationCommand decide(List<Detection> detections) {
    if (detections.isEmpty) return NavigationCommand.clear;

    bool hasCenter = false;
    bool hasLeft = false;
    bool hasRight = false;

    for (final d in detections) {
      switch (d.zone) {
        case DetectionZone.center: hasCenter = true; break;
        case DetectionZone.left:   hasLeft = true;   break;
        case DetectionZone.right:  hasRight = true;  break;
        case DetectionZone.none:   break;
      }
    }

    if (hasCenter) return NavigationCommand.stop;
    if (hasLeft)   return NavigationCommand.moveRight;
    if (hasRight)  return NavigationCommand.moveLeft;
    return NavigationCommand.moveForward;
  }
}
