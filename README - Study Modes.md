# MSK Study App — Quick Study & Custom Study

## What's new
- After choosing Muscle, Neuron, or Movement Quiz, choose **Quick Study** (one broad region or all) or **Custom Study** (multiple regions, joints, and movement types).
- Filters within the same dimension are combined using OR. Filters across dimensions use AND.
- The app displays the number of matching records and prevents starting with zero matches.
- Existing question types, answer choices, results, and question-count setting remain.
- Quiz answer distractors are drawn from the full data set so narrowly filtered quizzes still have answer options.

## Study data
Original records and answer fields were preserved. Each record has three appended fields: `region`, `joint`, and `action`, containing comma-separated tags. These tags were **automatically inferred** from descriptions, movement phrases and muscle names; they require anatomical review before high-stakes educational use. `Unclassified` indicates records that couldn't be assigned confidently. Some records have multiple regions/joints.

## Opening
Open `MSK Study App V1.xcodeproj` in Xcode, select the app target, then run. The project uses Xcode's file-system-synchronized folder group, which should pick up `StudyFilterView.swift` automatically. If Xcode does not show the file, add it to the app target manually.

## Validation limitations
The ZIP was checked structurally and metadata fields were checked programmatically. An Xcode/iOS build could not be run in this environment, so compile/runtime testing is still needed on a Mac.
