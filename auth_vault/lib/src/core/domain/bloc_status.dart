enum BlocStatus {
  init,
  loading,
  hasData,
  success,
  checking,
  error,
  validateError;

  bool get isLoading => this == loading;
  bool get isSuccess => this == success;
  bool get isError => this == error;
}
