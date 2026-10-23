///|
/// The `--bench` sampling mode (A-9.1/A-9.2; AD section 6).
///
/// This mode is deliberately **not** a cell run: it selects no cell from the
/// frozen table, compares no expectation, and therefore writes no failure
/// record and never creates `_gate/`. AD section 6 lists `--bench` beside
/// `--group` only as a sampling flag; it is not a cell comparison and is
/// exempt from the two-line self-report (`cells=... passed=...`). Stdout is
/// still exactly two lines: the canonical invocation printed by `main`, then
/// the bench report produced here.
///
/// Timing uses the core benchmark clock (`moonbitlang/core/bench`), which is
/// a public package: no new `extern` or `@env` binding is introduced, and the
/// runtime zero-I/O contract is unchanged. `monotonic_clock_end` reports
/// **microseconds** (core runtime `env.c` multiplies by 1e6), while the A-9
/// budget and the report are in milliseconds, so every elapsed value is
/// divided by `MICROSECONDS_PER_MILLISECOND` exactly once.
///
/// The word list is compared **order-sensitively**, unlike the cell
/// comparator (`compare.mbt`), which treats a list as a set: the bench text
/// is fixed and this port is deterministic, so the order is part of the
/// observed result and therefore part of the signature.

///|
/// Number of timed `analyze(text)` calls in one `--bench` run (A-9.2: the
/// result is checked 100 times in a row).
const BENCH_RUNS : Int32 = 100

///|
/// The A-9.1 budget: the median of the 100 timed calls must be at most 50 ms.
const BENCH_MEDIAN_BUDGET_MS : Double = 50.0

///|
/// Microseconds per millisecond, matching the unit of
/// `@bench.monotonic_clock_end`.
const MICROSECONDS_PER_MILLISECOND : Double = 1000.0

///|
/// The separator between two signature parts.
///
/// It is the ASCII unit separator (U+001F), which a tokenized word cannot
/// contain, so two different part arrays can never collapse into the same
/// joined signature.
const SIGNATURE_SEPARATOR : String = "\u{1F}"

///|
/// The 19 parts of one analysis result, one part per field of `TextStats`
/// (A-9.2: repeated evaluations must agree bit for bit).
///
/// The parts follow the spec section 4.2 field order: the nine integer
/// counters as decimal text, the word list as one part (its length followed
/// by the words joined with `|`), then the nine doubles as the decimal text
/// of their IEEE-754 bit pattern (`Double::reinterpret_as_uint64`, the same
/// identity rule as AD section 2.2). Two signatures are equal exactly when
/// all 19 fields are equal bit for bit; printed decimal scores are never
/// compared, so `-0.0` versus `0.0` and distinct NaN payloads stay
/// distinguishable.
///
/// The part count is the **A-9.2 coverage invariant**: `TextStats` has
/// exactly 19 fields, so a signature with a different number of parts would
/// mean that a field is not covered. `bench_wbtest.mbt` pins that count and
/// pins that every single field changes the signature.
fn signature_parts(stats : @moon_textstat.TextStats) -> Array[String] {
  [
    stats.char_count.to_string(),
    stats.letter_count.to_string(),
    stats.lexicon_count.to_string(),
    stats.sentence_count.to_string(),
    stats.syllable_count.to_string(),
    stats.polysyllabcount.to_string(),
    stats.monosyllabcount.to_string(),
    stats.difficult_words.to_string(),
    stats.difficult_words_list.length().to_string() +
    "|" +
    stats.difficult_words_list.join("|"),
    stats.long_word_count.to_string(),
    stats.reading_time.reinterpret_as_uint64().to_string(),
    stats.flesch_reading_ease.reinterpret_as_uint64().to_string(),
    stats.flesch_kincaid_grade.reinterpret_as_uint64().to_string(),
    stats.gunning_fog.reinterpret_as_uint64().to_string(),
    stats.smog_index.reinterpret_as_uint64().to_string(),
    stats.automated_readability_index.reinterpret_as_uint64().to_string(),
    stats.coleman_liau_index.reinterpret_as_uint64().to_string(),
    stats.linsear_write_formula.reinterpret_as_uint64().to_string(),
    stats.dale_chall_readability_score.reinterpret_as_uint64().to_string(),
  ]
}

///|
/// Run `analyze` once on the bench text. `None` records a raised
/// `TextstatError` instead of terminating the process, so a raise makes the
/// run unstable and the bench exits with 1 (A-9.2), rather than reporting a
/// half-collected sample set as stable.
fn bench_analyze(text : String) -> @moon_textstat.TextStats? {
  Some(@moon_textstat.analyze(text)) catch {
    _ => None
  }
}

///|
/// Format a non-negative millisecond duration with exactly three decimals.
///
/// The value is rounded to the nearest thousandth (half away from zero) and
/// printed as `<whole>.<three digits>`, independent of locale. The `--bench`
/// report uses this for both `median_ms` and `warmup_ms`.
///
/// The thousandths are counted in `Int64`, not `Int`: a 32-bit counter
/// saturates at 2,147,483,647 thousandths, i.e. a duration of about 24.8
/// days, and the saturated value would print a completely wrong number.
fn format_ms(value : Double) -> String {
  let thousandths = (value * 1000.0).round().to_int64()
  let whole = thousandths / 1000L
  let fraction = thousandths % 1000L
  let fraction_text = if fraction < 10L {
    "00" + fraction.to_string()
  } else if fraction < 100L {
    "0" + fraction.to_string()
  } else {
    fraction.to_string()
  }
  whole.to_string() + "." + fraction_text
}

///|
/// The median of the collected timing samples (A-9.1).
///
/// The input is copied before sorting, so the caller's array keeps its own
/// order. With an even number of samples the median is the mean of the two
/// middle values; with an odd number it is the middle value. An empty sample
/// set is an environment problem (EXIT=2), not a silent zero.
fn median_of(samples : Array[Double]) -> Double {
  if samples.length() == 0 {
    gate_fail("bench collected no timing samples")
  }
  let sorted = samples.copy()
  sorted.sort()
  let middle = sorted.length() / 2
  if sorted.length() % 2 == 0 {
    (sorted[middle - 1] + sorted[middle]) / 2.0
  } else {
    sorted[middle]
  }
}

///|
/// The A-9.2 stability verdict: all 100 results must agree bit for bit.
///
/// `evaluations` counts the runs that produced a result, `comparisons` the
/// runs that were compared against the reference signature, `mismatches` the
/// comparisons that found a difference, and `has_reference` tells whether a
/// reference signature was established at all.
///
/// The first successful evaluation becomes the reference and is never
/// compared with itself, so a fully consistent run performs exactly
/// `BENCH_RUNS - 1` comparisons. Requiring that exact count is the
/// **anti-vacuity guard**: a comparison that never happened must never be
/// reported as stable, and a run that raised must not be counted as one.
fn bench_stable(
  evaluations : Int32,
  comparisons : Int32,
  mismatches : Int32,
  has_reference : Bool,
) -> Bool {
  evaluations == BENCH_RUNS &&
  comparisons == BENCH_RUNS - 1 &&
  mismatches == 0 &&
  has_reference
}

///|
/// Run the `--bench` sampling mode and map its outcome to the exit contract.
///
/// The sequence is fixed: build the 600-code-point text, perform one warm-up
/// `analyze` call (dictionary and hyphenation tables initialize there, and its
/// own duration is reported separately as `warmup_ms`), then make
/// `BENCH_RUNS` timed calls. Each timed call brackets only the `analyze`
/// invocation with the monotonic clock; building the 19-part signature is
/// deliberately outside the timed region and cannot inflate the sample.
///
/// The median is the usual middle value, computed by `median_of`: the 100
/// samples are sorted and the median is the average of the 50th and 51st
/// values (1-based), i.e. indices 49 and 50. Stability holds when all 100
/// signatures are identical and no call raised, as decided by
/// `bench_stable`.
///
/// Exit code: 0 when `median_ms <= 50.0` and `stable`, otherwise 1. The
/// report line carries `runs=100 median_ms=<3 decimals> stable=<bool>
/// warmup_ms=<3 decimals>`.
fn run_bench() -> Unit {
  let text = bench_text()
  let warmup_start = @bench.monotonic_clock_start()
  let _warmup = bench_analyze(text)
  let warmup_ms = @bench.monotonic_clock_end(warmup_start) /
    MICROSECONDS_PER_MILLISECOND
  let samples : Array[Double] = []
  let mut evaluations = 0
  let mut comparisons = 0
  let mut mismatches = 0
  let mut has_reference = false
  let mut reference : String? = None
  for _ in 0..<BENCH_RUNS {
    let start = @bench.monotonic_clock_start()
    let stats = bench_analyze(text)
    let elapsed_ms = @bench.monotonic_clock_end(start) /
      MICROSECONDS_PER_MILLISECOND
    samples.push(elapsed_ms)
    match stats {
      Some(value) => {
        evaluations = evaluations + 1
        let signature = signature_parts(value).join(SIGNATURE_SEPARATOR)
        match reference {
          Some(first) => {
            comparisons = comparisons + 1
            if first != signature {
              mismatches = mismatches + 1
            }
          }
          None => {
            has_reference = true
            reference = Some(signature)
          }
        }
      }
      None => ()
    }
  }
  let stable = bench_stable(evaluations, comparisons, mismatches, has_reference)
  let median_ms = median_of(samples)
  println(
    "bench runs=" +
    BENCH_RUNS.to_string() +
    " median_ms=" +
    format_ms(median_ms) +
    " stable=" +
    stable.to_string() +
    " warmup_ms=" +
    format_ms(warmup_ms),
  )
  if stable && median_ms <= BENCH_MEDIAN_BUDGET_MS {
    exit_with_code(0)
  } else {
    exit_with_code(1)
  }
}
