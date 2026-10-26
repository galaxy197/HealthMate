/// Activate only after the admin Rules have been deployed and tested.
const adminRuntimeEnabled = bool.fromEnvironment(
  'HEALTHMATE_ENABLE_ADMIN_CONTROLS',
);
