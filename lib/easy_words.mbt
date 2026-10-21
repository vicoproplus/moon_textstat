///|
/// Easy-word list selected for `lang` (upstream `get_lang_easy_words`,
/// `_get_lang_easy_words.py:46-54`; spec §4.5.2).
///
/// The selection is decided by `lang_root(lang)` alone:
///
/// 1. when a resource exists for the root — `en` or `es` today — that list is
///    used;
/// 2. otherwise the English list is used, silently. Upstream emits a
///    `Warning` at this point; the library contract replaces the warning with
///    this documented fallback (spec §4.5.1), so nothing is printed or
///    recorded at run time. Because the warning is the only difference, the
///    returned words are what upstream would return after warning.
///
/// `@data.easy_words` already returns the loader's result: every line was
/// stripped (the Spanish file's literal `"que "`-style trailing spaces are
/// gone), lowercased and de-duplicated, so the array holds only non-empty
/// lowercase words. The array is the data package's read-only store.
///
/// `en` always exists, as one of the two embedded lists. A missing English
/// list therefore means the data package was built incorrectly; the internal
/// check aborts instead of silently degrading every lookup to "not easy".
fn easy_words_for_lang(lang : String) -> Array[String] {
  match @data.easy_words(lang_root(lang)) {
    Some(words) => words
    None =>
      match @data.easy_words("en") {
        Some(words) => words
        None => abort("missing embedded easy-word list: en (data invariant)")
      }
  }
}

///|
/// Whether `lowercase_word` belongs to the easy-word set selected for `lang`
/// (the membership step of upstream `is_difficult_word`,
/// `_is_difficult_word.py:38-45`; spec §4.5.2).
///
/// **Precondition: `lowercase_word` is already lowercase.** Upstream lowers
/// the word (`word = word.lower()`) before the set lookup; that lowering
/// belongs to the public entry (`difficult_words`, T-21) and must not be
/// repeated here, mirroring `syllables_for_word`'s case policy. Passing
/// `"The"` returns `false` even though `"the"` is easy, because the embedded
/// lists contain lowercase words only.
///
/// The lookup is a binary search over the list's own sorted order; see
/// `sorted_easy_words_contains` for why the comparator is not `String`'s
/// `Compare`.
///
/// This task's only callers are the white-box tests; T-21 wires the predicate
/// into `difficult_words`. `moon check` compiles without test files, so the
/// otherwise-correct unused-function warning is silenced here instead of
/// widening the visibility to `pub`.
// TEMP(T-20): remove this suppression in T-21, when `difficult_words` calls `is_easy_word`.
#warnings("-unused_value")
fn is_easy_word(lang : String, lowercase_word : String) -> Bool {
  sorted_easy_words_contains(easy_words_for_lang(lang), lowercase_word)
}

///|
/// Membership test over one sorted easy-word array.
///
/// The comparator is `String::lexical_compare` (UTF-16 code unit by code
/// unit), which matches the order in which the embedded lists were sorted.
/// `String`'s `Compare` impl is shortlex (`"b" < "ab"`), so using `<` or
/// `compare` here would disagree with the data order and could miss entries
/// that are present. The payloads contain BMP characters only, where this
/// order coincides with Python's code-point order.
///
/// The array is the data package's read-only store and is never mutated.
fn sorted_easy_words_contains(words : Array[String], word : String) -> Bool {
  let mut low = 0
  let mut high = words.length() - 1
  while low <= high {
    let mid = low + (high - low) / 2
    let order = words[mid].lexical_compare(word)
    if order == 0 {
      return true
    } else if order < 0 {
      low = mid + 1
    } else {
      high = mid - 1
    }
  }
  false
}
