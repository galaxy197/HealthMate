/// Only privileged, verified migration metadata may select an optimized query.
enum MealQueryMode { compatibility, partitioned, complete }

class MealQueryRead {
  const MealQueryRead({
    required this.branch,
    required this.documentCount,
    required this.fromCache,
  });
  final String branch;
  final int documentCount;
  final bool fromCache;
}
