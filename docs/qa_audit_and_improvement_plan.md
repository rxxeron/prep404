# Prep404 — Live BlueStacks QA Audit & Improvement Plan

> **Test Environment:** BlueStacks (`emulator-5554`, `900×1600`, 240dpi) · Live Supabase PostgreSQL · Date: **20 Nov 2026**
> **Screens Tested Live:** Onboarding (Steps 1–3) → Home Dashboard → Study Plan / Roadmap → Question Bank (University-wise & Subject-wise) → Daily Live Exam Arena → Exam Mode Selection → Live In-App Digital Exam → Exam History & Analytics → Profile & Settings (Light & Dark Mode)

---

## 1. Critical Hardcoded & Data-Integrity Bugs (P0 — Fix Immediately)

| # | Screen | What Was Found Live on BlueStacks | Exact Source in Code | Fix Plan |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **Study Plan / Roadmap** | Top bar shows `🔥 0` streak, while the Roadmap HUD right below hardcodes **`🔥 3-Day Streak`** even for a brand-new user with `0 XP`. | [roadmap_hud_bar.dart](file:///e:/PREP404/lib/features/practice_map/presentation/widgets/roadmap_hud_bar.dart#L191) | Bind directly to `UserProfile.streakDays` (or real DB streak service); show `0-Day Streak` / `Start Streak` when `0`. |
| **2** | **Study Plan / Roadmap** | Track selector says **`UIU — Engineering & CSE`**, yet Day 1 & Day 5 assign **`UIU PHARMACY Official Model Test`** (Chemistry/Pharmacy) to a CSE candidate. | `admission_plan_service.dart` / `practice_map` track filter | Filter roadmap milestones strictly by the candidate's selected `DisciplineCategory` / faculty (`engineering` vs `pharmacy` vs `business`), never mixing Pharmacy tests into CSE. |
| **3** | **Home Dashboard** | UIU card shows hardcoded fallback **`100 Marks • 90 Mins`** and **`2 Section Patterns`** (`English Grammar 50` + `Quantitative & Business Math 50`) even though UIU's official pattern is **75 marks** and the student picked **CSE + English**. | [university_roadmap_service.dart](file:///e:/PREP404/lib/core/services/university_roadmap_service.dart#L424) | Remove hardcoded `100 Marks` / generic 2-section fallback; pull all section patterns & mark breakdowns exclusively from `admission_test_patterns` in Supabase. |
| **4** | **Daily Live Exam Arena** | Hero card displays raw scraper dump **`UIU Real Admission Test - PYQ ENGLISH HEALER PYQ`** with **`297 Questions • 355 Mins • 100 Marks`** (a 6-hour 297-Q book dump masquerading as a daily exam, with `297 Marks` shown in the list below). | Database `exams` table (`PYQ ENGLISH HEALER PYQ`) + `daily_exam_live_card.dart` | Clean/curate `exams` so Daily Live Exams only select valid timed mock sets (20–100 Qs, 20–120 mins); never expose raw ingestion slugs or multi-hundred-question dumps as Daily Tests. |
| **5** | **Daily Live Exam Arena** | Contradictory copy: top-right says **`OPENS AT 10:00 AM`** and button is locked (`Exam Opens at 10:00 AM`), yet the line directly above says **`🔥 Today's Live Slot Open for UIU`**. Also hardcoded fallback `25 Qs / 30 Mins / 50 Marks` when API returns null. | [dashboard_today_test_card.dart](file:///e:/PREP404/lib/features/dashboard/presentation/widgets/dashboard_today_test_card.dart#L48-L69) & `daily_exam_live_card.dart` | Compute status copy strictly from the live exam window (`upcoming` → *"Opens at 10:00 AM"*, `live` → *"Live Now"*, `ended` → *"Window Closed"*). Render a clean empty state instead of fake `25 Qs / 30 Mins` fallback numbers. |
| **6** | **Select Exam Mode** | Opening a **Missed Practice** English-only test shows: (a) green **`LIVE EXAM`** badge, (b) hardcoded **`Standard syllabus: Higher Math, Quant Math, English, Physics & Analytical Reasoning`**, and (c) hardcoded **`RECOMMENDED FOR BRACU & NSU`** on a **UIU** exam. | [exam_mode_selection_view.dart](file:///e:/PREP404/lib/features/exam/presentation/widgets/exam_mode_selection_view.dart#L101-L140) | Pass `isPracticeMode` to switch badge to `PRACTICE MODE`; render actual exam subject/description from DB; make OMR badge university-agnostic (`AUTHENTIC EXAM HALL OMR`) or dynamically matched to target university. |
| **7** | **Core Model** | Static fallback catalog `PrivateUniversity.topPrivateUniversities` still embeds hardcoded `DateTime(2026, ...)` dates. | [university_target.dart](file:///e:/PREP404/lib/core/models/university_target.dart#L128-L342) | Deprecate/remove hardcoded dates from `university_target.dart` so all schedule data flows exclusively from Supabase `admission_cycles`. |

---

## 2. Critical UI / Accessibility & Layout Bugs Found Live (P1)

| # | Screen | Observed Bug on BlueStacks | Planned Fix |
| :-: | :--- | :--- | :--- |
| **8** | **Profile (Dark Mode)** | **Invisible text (Critical A11y):** `Batch: HSC '24` pill and **`Turn on notifications so you never miss practice!`** render dark text on dark plum containers — completely unreadable in Dark Mode. | Replace hardcoded dark text colors with `colors.textPrimary` / `colors.primary` theme tokens in `profile_settings_screen.dart` & `profile_menu_components.dart`. |
| **9** | **Live Digital Exam** | Filter pills **`All (20)` / `Answered (0)` / `Unanswered (20)`** are stacked **vertically** (3 full-width rows, ~240px tall!), consuming ~20% of the exam reading viewport. | Convert to a single compact horizontal segmented row (`height: 36–40px`) so the student sees full questions immediately. |
| **10** | **Live Digital Exam** | Crowded top bar with **duplicate exit controls** (`←` on the left AND `×` on the far right) plus unlabeled yellow OMR dot, timer, dark mode, and grid icon. | Remove duplicate exit button (keep single `←` with exit-confirmation dialog), label/tooltip the OMR switch, and move theme toggle into an overflow menu so the exam header stays calm and focused. |
| **11** | **Home Dashboard** | Giant **empty cream rectangle** below the target university card while `dailyTestFuture` loads slowly (or stalls). | Replace blank cream container with a lightweight shimmer card or collapse cleanly when no daily test is scheduled; parallelize dashboard queries so it resolves in <500ms. |
| **12** | **Question Bank** | (a) Top **55% of every card is empty gradient space**; (b) campus address uses a **calendar icon (`📅`)** instead of a location pin (`📍`); (c) every static Q-Bank card has a misleading red **`((•)) Live`** badge; (d) Subject-wise repeats labels (`[BIOLOGY] Biology`) and hides real question/chapter counts. | Redesign Q-Bank cards into compact, information-dense tiles: remove fake `Live` badges, fix `Icons.location_on_outlined`, show real DB `question_count` & `chapter_count` on Subject-wise cards, and update search hint & section title per sub-tab. |
| **13** | **Daily Test Filter Bar** | University filter chips (`BRAC`, `North South`, `AIUB`, `Ahsanullah`, `East We...`) are **not sorted A–Z**, and the active university (`UIU`) isn't auto-scrolled into view or pinned first. | Pin the user's selected target university first (or sort strictly A–Z with `AppSorter`) and auto-scroll the active chip into view. |
| **14** | **Profile & Settings** | (a) `Edit All` wraps onto a separate line below `Admission Profile & Setup`; (b) `Linked Accounts` stacks 3 tiny `f + / G + /  +` pills vertically in a giant blank box and doesn't show that Google is already linked (plus shows Apple Sign-In on Android); (c) `Upgrade` and `Subscription` are redundant back-to-back rows. | Align `Edit All` inline with the section header; display `Linked Accounts` as a clean horizontal row showing real Supabase `user.identities` (e.g. `Google · Connected`) and hiding Apple on Android; merge `Upgrade` & `Subscription` into one clear `Plan & Billing` row. |

---

## 3. Strategic Product & UX Improvements (P2 — Better Planning)

1. **Roadmap Milestone Clarity**: Strip redundant prefixes (`"UIU ENGINEERING Official Model Test - "`) from milestone titles so the subject/topic (`English Grammar`, `Higher Math`, `Physics`) is immediately readable without ellipsis truncation, and fix `"All Quest (16)"` → `"All Quests (16)"`.
2. **Real User Avatar**: Show the user's Google profile photo or monogram initials (`RH`) in the top-right app bar and Profile header instead of repeating the Prep404 logo.
3. **Onboarding Faculty Ordering**: Sort faculty headers alphabetically inside expanded university cards in `UniversitySelectionStep` to match the Universal Ascending Order rule.
4. **Unified Exam Data Contract**: Add a server-side validation rule in Admin/Backend so an exam cannot be published to `Daily Live Arena` if `question_count > 150` or `duration_minutes > 180` (preventing book-ingestion dumps from ever leaking into student daily tests).

---

> [!IMPORTANT]
> **Ready to execute:** Tell me if you want me to start fixing **all P0 + P1 bugs right now** (removing every hardcoded value, fixing Dark Mode, compacting the Exam filter bar, fixing the Roadmap Pharmacy/CSE mix-up, and polishing Q-Bank/Profile) and verify every fix live on BlueStacks.
