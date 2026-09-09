import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

void processImage(InputImage inputImage, FaceDetector faceDetector) async {
  final List<Face> faces = await faceDetector.processImage(inputImage);

  for (Face face in faces) {
    // 1. Get Left and Right Eye Contours
    final FaceContour? leftEyeContour = face.contours[FaceContourType.leftEye];
    final FaceContour? rightEyeContour = face.contours[FaceContourType.rightEye];

    if (leftEyeContour != null && rightEyeContour != null) {
      // 2. Compute Gaze direction relative to the eye bounding box
      final String gaze = calculateGazeDirection(leftEyeContour.points);
      print("Detected Gaze: $gaze");
    }

    // 3. Detect Blinks / Eye State
    if (face.leftEyeOpenProbability != null && face.rightEyeOpenProbability != null) {
      final double leftOpenProb = face.leftEyeOpenProbability!;
      final double rightOpenProb = face.rightEyeOpenProbability!;
      
      bool isBlinking = leftOpenProb < 0.25 && rightOpenProb < 0.25;
      if (isBlinking) {
        print("User Blinked");
      }
    }
  }
}

String calculateGazeDirection(List<Point<int>> eyePoints) {
  if (eyePoints.isEmpty) return "Unknown";

  // Find boundaries of the eye contour (Bounding Box)
  int minX = eyePoints.first.x;
  int maxX = eyePoints.first.x;
  int minY = eyePoints.first.y;
  int maxY = eyePoints.first.y;

  for (var point in eyePoints) {
    minX = min(minX, point.x);
    maxX = max(maxX, point.x);
    minY = min(minY, point.y);
    maxY = max(maxY, point.y);
  }

  // Calculate Eye Center from points
  double sumX = 0;
  double sumY = 0;
  for (var point in eyePoints) {
    sumX += point.x;
    sumY += point.y;
  }
  double currentCenterX = sumX / eyePoints.length;
  
  // Calculate relative Horizontal position within the eye frame [0.0 - 1.0]
  double eyeWidth = (maxX - minX).toDouble();
  if (eyeWidth == 0) return "Center";

  double relativeX = (currentCenterX - minX) / eyeWidth;

  // Thresholds for gaze direction
  if (relativeX < 0.42) {
    return "Looking Left";
  } else if (relativeX > 0.58) {
    return "Looking Right";
  } else {
    return "Center Forward";
  }
}