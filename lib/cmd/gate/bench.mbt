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
/// The 19-field bit signature of one analysis result (A-9.2: repeated
/// evaluations must agree bit for bit).
///
/// The parts follow the spec section 4.2 field order: the nine integer
/// counters as decimal text, the word list as its length followed by the
/// words joined with `|`, then the nine doubles as the decimal text of their
/// IEEE-754 bit pattern (`Double::reinterpret_as_uint64`, the same identity
/// rule as AD section 2.2). Two signatures are equal exactly when all 19
/// fields are equal bit for bit; printed decimal scores are never compared,
/// so `-0.0` versus `0.0` and distinct NaN payloads stay distinguishable.
fn stats_signature(stats : @moon_textstat.TextStats) -> String {
  let parts : Array[String] = [
    stats.char_count.to_string(),
    stats.letter_count.to_string(),
    stats.lexicon_count.to_string(),
    stats.sentence_count.to_string(),
    stats.syllable_count.to_string(),
    stats.polysyllabcount.to_string(),
    stats.monosyllabcount.to_string(),
    stats.difficult_words.to_string(),
    stats.difficult_words_list.length().to_string(),
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
  parts.join(",")
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
fn format_ms(value : Double) -> String {
  let thousandths = (value * 1000.0).round().to_int()
  let whole = thousandths / 1000
  let fraction = thousandths % 1000
  let fraction_text = if fraction < 10 {
    "00" + fraction.to_string()
  } else if fraction < 100 {
    "0" + fraction.to_string()
  } else {
    fraction.to_string()
  }
  whole.to_string() + "." + fraction_text
}

///|
/// Run the `--bench` sampling mode and map its outcome to the exit contract.
///
/// The sequence is fixed: build the 600-code-point text, perform one warm-up
/// `analyze` call (dictionary and hyphenation tables initialize there, and its
/// own duration is reported separately as `warmup_ms`), then make
/// `BENCH_RUNS` timed calls. Each timed call brackets only the `analyze`
/// invocation with the monotonic clock; building the 19-field signature is
/// deliberately outside the timed region and cannot inflate the sample.
///
/// The median is the usual middle value: the 100 samples are sorted and the
/// median is the average of the 50th and 51st values (1-based), i.e. indices
/// 49 and 50. Stability holds when all 100 signatures are identical and no
/// call raised.
///
/// The `compared` counter is the anti-vacuity guard of A-9.2: it is
/// incremented once per successfully analyzed run, and the run is reported
/// unstable unless it reaches `BENCH_RUNS`. Without it a comparison that
/// never reached the reference signature would still print `stable=true`.
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
  let mut compared = 0
  let mut stable = true
  let mut reference : String? = None
  for _ in 0..<BENCH_RUNS {
    let start = @bench.monotonic_clock_start()
    let stats = bench_analyze(text)
    let elapsed_ms = @bench.monotonic_clock_end(start) /
      MICROSECONDS_PER_MILLISECOND
    samples.push(elapsed_ms)
    match stats {
      Some(value) => {
        let signature = stats_signature(value)
        compared = compared + 1
        match reference {
          Some(first) => if first != signature { stable = false }
          None => reference = Some(signature)
        }
      }
      None => stable = false
    }
  }
  if compared != BENCH_RUNS {
    stable = false
  }
  samples.sort()
  let middle = BENCH_RUNS / 2
  let median_ms = if BENCH_RUNS % 2 == 0 {
    (samples[middle - 1] + samples[middle]) / 2.0
  } else {
    samples[middle]
  }
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
