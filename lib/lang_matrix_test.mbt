///|
/// The T-35 language matrix: eleven supported codes × the six `[ALIGN]` fields
/// of spec §4.5.3, on the probe sentence shared with the oracle.
///
/// Every cell is copied from `docs/facts/oracle_smoke.json` `lang_probes`
/// (never derived from the port) and the row order is the oracle's:
/// `en`, `en_US`, `en_GB`, `de_DE`, `es_ES`, `fr_FR`, `it_IT`, `nl_NL`,
/// `pl_PL`, `ru_RU`, `hu_HU`. Columns are `syllable_count`,
/// `flesch_reading_ease`, `gunning_fog`, `difficult_words`,
/// `polysyllabcount`, `monosyllabcount`.
///
/// Two silent-fallback facts (FE2) are visible in the rows: `pl_PL` inherits
/// the English FRE constants, so its reading ease repeats `en_US`'s
/// `-109.45499999999998`, while its syllable count is still Polish; and
/// `de_DE`/`fr_FR` fall back to the English easy-word list, so the probe yields
/// four difficult words exactly like English. `es_ES` is the exception with
/// three, because its own list contains `international`.
///
/// `ar` and `xx_YY` are not in this test: they have no numeric row and are
/// covered by the failure test below (A-5.2). `pt` is documentation only and is
/// likewise absent here (A-4.4).
test "language matrix: 11 codes x 6 fields match the oracle" {
  let probe = "The extraordinary readability of international documentation."
  let rows : Array[(String, Int32, Double, Double, Int32, Int32, Int32)] = [
    ("en", 22, -109.45499999999998, 29.06666666666667, 4, 4, 2),
    ("en_US", 22, -109.45499999999998, 29.06666666666667, 4, 4, 2),
    ("en_GB", 22, -109.45499999999998, 29.06666666666667, 4, 4, 2),
    ("de_DE", 25, -69.75000000000003, 29.06666666666667, 4, 4, 2),
    ("es_ES", 23, -29.28, 22.400000000000002, 3, 4, 2),
    ("fr_FR", 23, -81.22333333333333, 29.06666666666667, 4, 4, 2),
    ("it_IT", 22, -10.800000000000011, 29.06666666666667, 4, 4, 2),
    ("nl_NL", 26, -132.41166666666663, 29.06666666666667, 4, 4, 2),
    ("pl_PL", 22, -109.45499999999998, 29.06666666666667, 4, 4, 2),
    ("ru_RU", 6, 138.935, 2.4000000000000004, 0, 0, 6),
    ("hu_HU", 23, -23.504999999999995, 22.400000000000002, 4, 4, 2),
  ]
  assert_eq(11, rows.length())
  for row in rows {
    let (lang, syllables, fre, fog, difficult, poly, mono) = row
    assert_eq(syllables, @moon_textstat.syllable_count(probe, lang~))
    assert_eq(fre, @moon_textstat.flesch_reading_ease(probe, lang~))
    assert_eq(fog, @moon_textstat.gunning_fog(probe, lang~))
    assert_eq(difficult, @moon_textstat.difficult_words(probe, lang~))
    assert_eq(poly, @moon_textstat.polysyllabcount(probe, lang~))
    assert_eq(mono, @moon_textstat.monosyllabcount(probe, lang~))
  }
}

///|
/// Run `metric` and return the text of its product-facing `MetricFailure`, or
/// a sentinel when it returns a value / raises something else. The sentinels
/// make the three `contains` assertions below fail instead of silently
/// accepting a wrong shape.
fn[T] capture_metric_failure(
  run : () -> T raise @moon_textstat.TextstatError,
) -> String {
  try {
    let _ = run()
    "<no failure>"
  } catch {
    @moon_textstat.MetricFailure(message) => message
    _ => "<other failure>"
  }
}

///|
/// A-5.4 text contract: metric name, language code and a non-empty reason.
/// The exact upstream text (`KeyError: None`) is deliberately *not* compared —
/// the enrichment is a product contract, not an alignment item (§4.5.4).
fn assert_metric_failure_text(
  message : String,
  metric : String,
  lang : String,
) -> Unit raise {
  assert_true(message.contains(metric), msg="missing metric name: " + message)
  assert_true(message.contains(lang), msg="missing language code: " + message)
  assert_true(
    message.contains("no hyphenation dictionary"),
    msg="missing failure reason: " + message,
  )
}

///|
/// The two failure rows of the matrix (A-5.2): `ar` and `xx_YY` must fail all
/// six fields on the probe sentence instead of returning a value, and the
/// caught error must be the product-facing `MetricFailure` whose text carries
/// the three items of A-5.4. No English number is substituted (D-14/FE3).
test "language matrix: ar and xx_YY fail all six fields" {
  let probe = "The extraordinary readability of international documentation."
  for lang in ["ar", "xx_YY"] {
    let syllables = capture_metric_failure(() => {
      @moon_textstat.syllable_count(probe, lang~)
    })
    assert_metric_failure_text(syllables, "syllable_count", lang)
    let fre = capture_metric_failure(() => {
      @moon_textstat.flesch_reading_ease(probe, lang~)
    })
    assert_metric_failure_text(fre, "flesch_reading_ease", lang)
    let fog = capture_metric_failure(() => {
      @moon_textstat.gunning_fog(probe, lang~)
    })
    assert_metric_failure_text(fog, "gunning_fog", lang)
    let difficult = capture_metric_failure(() => {
      @moon_textstat.difficult_words(probe, lang~)
    })
    assert_metric_failure_text(difficult, "difficult_words", lang)
    let poly = capture_metric_failure(() => {
      @moon_textstat.polysyllabcount(probe, lang~)
    })
    assert_metric_failure_text(poly, "polysyllabcount", lang)
    let mono = capture_metric_failure(() => {
      @moon_textstat.monosyllabcount(probe, lang~)
    })
    assert_metric_failure_text(mono, "monosyllabcount", lang)
  }
}

///|
/// The empty-string exception stays: `syllable_count("")` returns 0 before any
/// dictionary lookup, and the entries that never resolve a dictionary on
/// wordless text keep their zeros for `ar`/`xx_YY` as well (spec §4.3.3). This
/// is the upstream `if not text: return 0` order, not a swallowed failure.
test "language matrix: unsupported languages keep the empty-string zeros" {
  for lang in ["ar", "xx_YY"] {
    assert_eq(0, @moon_textstat.syllable_count("", lang~))
    assert_eq(0, @moon_textstat.polysyllabcount("", lang~))
    assert_eq(0, @moon_textstat.monosyllabcount("", lang~))
    assert_eq(0, @moon_textstat.difficult_words("", lang~))
    assert_eq(0.0, @moon_textstat.flesch_reading_ease("", lang~))
    assert_eq(0.0, @moon_textstat.gunning_fog("", lang~))
  }
}

///|
/// Documentation only — `pt` is **not** an acceptance item (A-4.4, R-33 b): it
/// is absent from the oracle's thirteen `lang_probes` keys and from FR-27's
/// eight non-English roots, so it contributes no matrix cell and no gate cell.
///
/// Its mixed behavior (spec §4.5.1/§4.5.3, C-6/E-29) is recorded here for
/// readers: the language constants and the easy-word list silently fall back to
/// English, so an all-easy English sentence scores exactly as under `en_US`
/// without touching a dictionary; the hyphenation dictionary, however, is
/// resolved to `hyph_pt_BR.dic`, which is not embedded, so any non-easy word
/// fails at the dictionary layer. No expected Portuguese number is asserted.
test "documentation only: pt falls back to English but has no dictionary" {
  let all_easy = "the cat sat on the mat"
  // FE2: constants and easy words fall back to English. Gunning Fog's
  // all-easy path never asks for a syllable, so this value is observable.
  assert_eq(
    @moon_textstat.gunning_fog(all_easy, lang="en_US"),
    @moon_textstat.gunning_fog(all_easy, lang="pt"),
  )
  assert_eq(0, @moon_textstat.difficult_words(all_easy, lang="pt"))
  // FE3: hyph_pt_BR.dic is outside the embedded set, so the probe fails.
  let probe = "The extraordinary readability of international documentation."
  let message = capture_metric_failure(() => {
    @moon_textstat.syllable_count(probe, lang="pt")
  })
  assert_true(message.contains("no hyphenation dictionary for 'pt'"))
}
