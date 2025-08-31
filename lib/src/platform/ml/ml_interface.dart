/// Cross-platform machine learning interface
abstract class CrossPlatformML {
  /// Initialize the ML system
  Future<void> initialize();

  /// Close the ML system
  Future<void> close();

  /// Check if the ML system is ready
  bool get isReady;

  /// Get the platform name
  String get platform;

  /// Load a model from file or URL
  Future<void> loadModel(String modelPath);

  /// Run inference on input data
  Future<List<double>> runInference(List<double> input);

  /// Get model information
  Future<ModelInfo> getModelInfo();

  /// Get performance metrics
  Future<MLPerformanceMetrics> getPerformanceMetrics();
}

/// Model information
class ModelInfo {
  final String name;
  final String version;
  final int inputSize;
  final int outputSize;
  final String platform;
  final DateTime loadedAt;

  ModelInfo({
    required this.name,
    required this.version,
    required this.inputSize,
    required this.outputSize,
    required this.platform,
    required this.loadedAt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'version': version,
    'inputSize': inputSize,
    'outputSize': outputSize,
    'platform': platform,
    'loadedAt': loadedAt.toIso8601String(),
  };
}

/// ML performance metrics
class MLPerformanceMetrics {
  final Duration averageInferenceTime;
  final int totalInferences;
  final double memoryUsageMB;
  final DateTime lastInference;

  MLPerformanceMetrics({
    required this.averageInferenceTime,
    required this.totalInferences,
    required this.memoryUsageMB,
    required this.lastInference,
  });

  Map<String, dynamic> toJson() => {
    'averageInferenceTime': averageInferenceTime.inMicroseconds,
    'totalInferences': totalInferences,
    'memoryUsageMB': memoryUsageMB,
    'lastInference': lastInference.toIso8601String(),
  };
}
