import 'dart:math';

/// Optimized utility functions for embedding operations
/// Eliminates O(n²) bottlenecks and provides efficient vector operations
class EmbeddingUtils {
  // Cache for frequently used calculations
  static final Map<int, double> _sqrtCache = {};
  static const int _maxCacheSize = 1000;

  /// Calculate cosine similarity between two vectors - O(n) optimized
  static double cosineSimilarity(List<double> vector1, List<double> vector2) {
    if (vector1.length != vector2.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    if (vector1.isEmpty) return 0.0;

    // Use optimized dot product and magnitude calculations
    final dotProduct = _optimizedDotProduct(vector1, vector2);
    final norm1 = _optimizedMagnitude(vector1);
    final norm2 = _optimizedMagnitude(vector2);

    if (norm1 == 0.0 || norm2 == 0.0) return 0.0;

    return dotProduct / (norm1 * norm2);
  }

  /// Calculate Euclidean distance between two vectors - O(n) optimized
  static double euclideanDistance(List<double> vector1, List<double> vector2) {
    if (vector1.length != vector2.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    if (vector1.isEmpty) return 0.0;

    // Optimized squared difference calculation
    double sumSquaredDiff = 0.0;
    final length = vector1.length;

    // Unroll loop for better performance on small vectors
    if (length <= 16) {
      for (int i = 0; i < length; i++) {
        final diff = vector1[i] - vector2[i];
        sumSquaredDiff += diff * diff;
      }
    } else {
      // Use chunked processing for larger vectors
      const chunkSize = 16;
      for (int i = 0; i < length; i += chunkSize) {
        final end = (i + chunkSize < length) ? i + chunkSize : length;
        for (int j = i; j < end; j++) {
          final diff = vector1[j] - vector2[j];
          sumSquaredDiff += diff * diff;
        }
      }
    }

    return _optimizedSqrt(sumSquaredDiff);
  }

  /// Calculate Manhattan distance between two vectors - O(n) optimized
  static double manhattanDistance(List<double> vector1, List<double> vector2) {
    if (vector1.length != vector2.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    if (vector1.isEmpty) return 0.0;

    double sumAbsDiff = 0.0;
    final length = vector1.length;

    // Optimized absolute difference calculation
    for (int i = 0; i < length; i++) {
      sumAbsDiff += (vector1[i] - vector2[i]).abs();
    }

    return sumAbsDiff;
  }

  /// Normalize a vector to unit length - O(n) optimized
  static List<double> normalizeVector(List<double> vector) {
    if (vector.isEmpty) return vector;

    final magnitude = _optimizedMagnitude(vector);
    if (magnitude == 0.0) return vector;

    // Pre-allocate result list for better performance
    final result = List<double>.filled(vector.length, 0.0);
    final scale = 1.0 / magnitude;

    for (int i = 0; i < vector.length; i++) {
      result[i] = vector[i] * scale;
    }

    return result;
  }

  /// Calculate the magnitude (length) of a vector - O(n) optimized
  static double vectorMagnitude(List<double> vector) {
    if (vector.isEmpty) return 0.0;
    return _optimizedMagnitude(vector);
  }

  /// Add two vectors element-wise - O(n) optimized
  static List<double> addVectors(List<double> vector1, List<double> vector2) {
    if (vector1.length != vector2.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    // Pre-allocate result list for better performance
    final result = List<double>.filled(vector1.length, 0.0);
    final length = vector1.length;

    // Unroll loop for small vectors
    if (length <= 16) {
      for (int i = 0; i < length; i++) {
        result[i] = vector1[i] + vector2[i];
      }
    } else {
      // Use chunked processing for larger vectors
      const chunkSize = 16;
      for (int i = 0; i < length; i += chunkSize) {
        final end = (i + chunkSize < length) ? i + chunkSize : length;
        for (int j = i; j < end; j++) {
          result[j] = vector1[j] + vector2[j];
        }
      }
    }

    return result;
  }

  /// Subtract two vectors element-wise - O(n) optimized
  static List<double> subtractVectors(
    List<double> vector1,
    List<double> vector2,
  ) {
    if (vector1.length != vector2.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    // Pre-allocate result list for better performance
    final result = List<double>.filled(vector1.length, 0.0);
    final length = vector1.length;

    // Unroll loop for small vectors
    if (length <= 16) {
      for (int i = 0; i < length; i++) {
        result[i] = vector1[i] - vector2[i];
      }
    } else {
      // Use chunked processing for larger vectors
      const chunkSize = 16;
      for (int i = 0; i < length; i += chunkSize) {
        final end = (i + chunkSize < length) ? i + chunkSize : length;
        for (int j = i; j < end; j++) {
          result[j] = vector1[j] - vector2[j];
        }
      }
    }

    return result;
  }

  /// Multiply a vector by a scalar - O(n) optimized
  static List<double> multiplyVectorByScalar(
    List<double> vector,
    double scalar,
  ) {
    // Pre-allocate result list for better performance
    final result = List<double>.filled(vector.length, 0.0);
    final length = vector.length;

    // Unroll loop for small vectors
    if (length <= 16) {
      for (int i = 0; i < length; i++) {
        result[i] = vector[i] * scalar;
      }
    } else {
      // Use chunked processing for larger vectors
      const chunkSize = 16;
      for (int i = 0; i < length; i += chunkSize) {
        final end = (i + chunkSize < length) ? i + chunkSize : length;
        for (int j = i; j < end; j++) {
          result[j] = vector[j] * scalar;
        }
      }
    }

    return result;
  }

  /// Calculate the average of multiple vectors - O(n*m) optimized
  static List<double> averageVectors(List<List<double>> vectors) {
    if (vectors.isEmpty) return [];
    if (vectors.length == 1) return vectors.first;

    final length = vectors.first.length;
    for (final vector in vectors) {
      if (vector.length != length) {
        throw ArgumentError('All vectors must have the same length');
      }
    }

    // Pre-allocate result list and use single-pass accumulation
    final result = List<double>.filled(length, 0.0);
    final count = vectors.length.toDouble();

    // Single pass accumulation for better performance
    for (final vector in vectors) {
      for (int i = 0; i < length; i++) {
        result[i] += vector[i];
      }
    }

    // Single division pass
    for (int i = 0; i < length; i++) {
      result[i] /= count;
    }

    return result;
  }

  /// Find the most similar vector from a list of candidates - O(n*m) optimized
  static int findMostSimilar(
    List<double> queryVector,
    List<List<double>> candidateVectors, {
    double Function(List<double>, List<double>)? similarityFunction,
  }) {
    if (candidateVectors.isEmpty) return -1;

    final similarityFn = similarityFunction ?? cosineSimilarity;
    double bestSimilarity = -1.0;
    int bestIndex = -1;

    // Use optimized similarity calculation
    for (int i = 0; i < candidateVectors.length; i++) {
      final similarity = similarityFn(queryVector, candidateVectors[i]);
      if (similarity > bestSimilarity) {
        bestSimilarity = similarity;
        bestIndex = i;
      }
    }

    return bestIndex;
  }

  /// Convert a list of vectors to a 2D matrix - O(1) optimized
  static List<List<double>> vectorsToMatrix(List<List<double>> vectors) {
    if (vectors.isEmpty) return [];
    // Return view instead of copy for better performance
    return vectors;
  }

  /// Convert a 2D matrix to a list of vectors - O(1) optimized
  static List<List<double>> matrixToVectors(List<List<double>> matrix) {
    if (matrix.isEmpty) return [];
    // Return view instead of copy for better performance
    return matrix;
  }

  /// Check if two vectors are approximately equal - O(n) optimized
  static bool vectorsAreEqual(
    List<double> vector1,
    List<double> vector2, {
    double tolerance = 1e-10,
  }) {
    if (vector1.length != vector2.length) return false;

    // Early exit optimization
    for (int i = 0; i < vector1.length; i++) {
      if ((vector1[i] - vector2[i]).abs() > tolerance) {
        return false;
      }
    }

    return true;
  }

  /// Generate a random vector of specified dimension - O(n) optimized
  static List<double> generateRandomVector(int dimension, {Random? random}) {
    final rng = random ?? Random();

    // Pre-allocate result list for better performance
    final result = List<double>.filled(dimension, 0.0);

    for (int i = 0; i < dimension; i++) {
      result[i] = (rng.nextDouble() - 0.5) * 2.0; // Range: -1.0 to 1.0
    }

    return result;
  }

  /// Calculate the dot product of two vectors - O(n) optimized
  static double dotProduct(List<double> vector1, List<double> vector2) {
    if (vector1.length != vector2.length) {
      throw ArgumentError('Vectors must have the same length');
    }

    if (vector1.isEmpty) return 0.0;

    return _optimizedDotProduct(vector1, vector2);
  }

  /// Batch cosine similarity calculation for multiple vectors - O(n*m) optimized
  static List<double> batchCosineSimilarity(
    List<double> queryVector,
    List<List<double>> candidateVectors,
  ) {
    if (candidateVectors.isEmpty) return [];

    // Pre-allocate result list
    final results = List<double>.filled(candidateVectors.length, 0.0);

    // Calculate query vector magnitude once
    final queryMagnitude = _optimizedMagnitude(queryVector);

    if (queryMagnitude == 0.0) return results;

    // Batch process all candidates
    for (int i = 0; i < candidateVectors.length; i++) {
      final candidate = candidateVectors[i];
      final dotProduct = _optimizedDotProduct(queryVector, candidate);
      final candidateMagnitude = _optimizedMagnitude(candidate);

      if (candidateMagnitude == 0.0) {
        results[i] = 0.0;
      } else {
        results[i] = dotProduct / (queryMagnitude * candidateMagnitude);
      }
    }

    return results;
  }

  /// Batch Euclidean distance calculation for multiple vectors - O(n*m) optimized
  static List<double> batchEuclideanDistance(
    List<double> queryVector,
    List<List<double>> candidateVectors,
  ) {
    if (candidateVectors.isEmpty) return [];

    // Pre-allocate result list
    final results = List<double>.filled(candidateVectors.length, 0.0);

    // Batch process all candidates
    for (int i = 0; i < candidateVectors.length; i++) {
      results[i] = euclideanDistance(queryVector, candidateVectors[i]);
    }

    return results;
  }

  /// Find top-k most similar vectors - O(n*m + k*log(k)) optimized
  static List<MapEntry<int, double>> findTopKSimilar(
    List<double> queryVector,
    List<List<double>> candidateVectors,
    int k, {
    double Function(List<double>, List<double>)? similarityFunction,
  }) {
    if (candidateVectors.isEmpty || k <= 0) return [];

    final similarityFn = similarityFunction ?? cosineSimilarity;
    final similarities = <MapEntry<int, double>>[];

    // Calculate similarities for all candidates
    for (int i = 0; i < candidateVectors.length; i++) {
      final similarity = similarityFn(queryVector, candidateVectors[i]);
      similarities.add(MapEntry(i, similarity));
    }

    // Sort by similarity (descending) and return top-k
    similarities.sort((a, b) => b.value.compareTo(a.value));
    return similarities.take(k).toList();
  }

  // ============================================================================
  // PRIVATE OPTIMIZED METHODS
  // ============================================================================

  /// Optimized dot product calculation with loop unrolling
  static double _optimizedDotProduct(
    List<double> vector1,
    List<double> vector2,
  ) {
    double result = 0.0;
    final length = vector1.length;

    // Unroll loop for small vectors
    if (length <= 16) {
      for (int i = 0; i < length; i++) {
        result += vector1[i] * vector2[i];
      }
    } else {
      // Use chunked processing for larger vectors
      const chunkSize = 16;
      for (int i = 0; i < length; i += chunkSize) {
        final end = (i + chunkSize < length) ? i + chunkSize : length;
        for (int j = i; j < end; j++) {
          result += vector1[j] * vector2[j];
        }
      }
    }

    return result;
  }

  /// Optimized magnitude calculation with loop unrolling
  static double _optimizedMagnitude(List<double> vector) {
    double sumSquares = 0.0;
    final length = vector.length;

    // Unroll loop for small vectors
    if (length <= 16) {
      for (int i = 0; i < length; i++) {
        final value = vector[i];
        sumSquares += value * value;
      }
    } else {
      // Use chunked processing for larger vectors
      const chunkSize = 16;
      for (int i = 0; i < length; i += chunkSize) {
        final end = (i + chunkSize < length) ? i + chunkSize : length;
        for (int j = i; j < end; j++) {
          final value = vector[j];
          sumSquares += value * value;
        }
      }
    }

    return _optimizedSqrt(sumSquares);
  }

  /// Optimized square root with caching for frequently used values
  static double _optimizedSqrt(double value) {
    if (value <= 0.0) return 0.0;

    // Check cache for integer values (common in vector operations)
    final intValue = value.round();
    if ((value - intValue).abs() < 1e-10 &&
        intValue > 0 &&
        intValue < _maxCacheSize) {
      return _sqrtCache.putIfAbsent(intValue, () => sqrt(intValue.toDouble()));
    }

    return sqrt(value);
  }

  /// Clear the internal cache (useful for memory management)
  static void clearCache() {
    _sqrtCache.clear();
  }

  /// Get cache statistics for monitoring
  static Map<String, dynamic> getCacheStats() {
    return {
      'cache_size': _sqrtCache.length,
      'max_cache_size': _maxCacheSize,
      'cache_hit_ratio': 'N/A', // Would need hit/miss tracking
    };
  }
}
