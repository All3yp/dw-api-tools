@{
  Severity     = @('Error', 'Warning')
  ExcludeRules = @(
    # CLI UX intentionally prints to the host.
    'PSAvoidUsingWriteHost'
  )
}
