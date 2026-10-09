/// A backend error that Core's network layer has already handled: reported
/// or recorded as a breadcrumb. `ProviderFailureObserver` skips it so it is
/// never reported twice.
///
/// The network layer defines its kinds as subclasses.
abstract class ApiException implements Exception {
  const ApiException();
}
