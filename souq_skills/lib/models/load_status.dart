/// Whether data a screen needs is still loading or failed to load, with a
/// way to try again. Lets a screen tell "not loaded yet" from "not found".
class LoadStatus {
  const LoadStatus({this.isLoading = false, this.error, this.onRetry});

  /// Nothing is loading and nothing failed.
  static const ready = LoadStatus();

  final bool isLoading;

  /// What went wrong, when loading failed.
  final String? error;
  final void Function()? onRetry;
}
