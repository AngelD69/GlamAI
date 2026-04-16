class FaceShapeResult {
  final String faceShape;
  final double confidence;
  final Map<String, double> allScores;

  const FaceShapeResult({
    required this.faceShape,
    required this.confidence,
    required this.allScores,
  });

  factory FaceShapeResult.fromJson(Map<String, dynamic> json) =>
      FaceShapeResult(
        faceShape: json['face_shape'] as String,
        confidence: (json['confidence'] as num).toDouble(),
        allScores: (json['all_scores'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toDouble()),
        ),
      );
}
