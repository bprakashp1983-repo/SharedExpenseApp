import Foundation

/// ISO 4217 currency code used throughout the app.
/// Change this to your locale's code (e.g. "EUR", "GBP", "INR").
let currencyCode   = Locale.current.currency?.identifier ?? "USD"
let currencySymbol = Locale.current.currencySymbol ?? "$"
