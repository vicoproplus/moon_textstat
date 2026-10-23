///|
/// Reading time in seconds (spec §4.2 unit: seconds).
///
/// Literally `ms_per_char * count_chars(text, ignore_spaces=True) / 1000`
/// (upstream `backend/metrics/_reading_time.py`). Python evaluates the
/// multiplication before the division, so the expression keeps that order:
/// `ms_per_char * chars / 1000`, never `ms_per_char * (chars / 1000)`.
///
/// `char_count` already skips Python whitespace, so empty, whitespace-only and
/// punctuation-only inputs follow spec §4.3.3 (0.0 / 0.0 / 0.02938 with the
/// default 14.69 ms per character). The metric is language-independent: no
/// `lang` parameter, no dictionary lookup, no failure channel.
pub fn reading_time(text : String, ms_per_char~ : Double = 14.69) -> Double {
  ms_per_char * char_count(text).to_double() / 1000.0
}
