# Compact AI package acceptance checks

Candidate: Gemma 3 270M IT, Q4_K_M, pinned to bartowski conversion revision d127a4e2c6ed47fdf409a956867b604c040432f9. The normal product UI remains CiteCoach AI.

This change has not established that the candidate is faster or more accurate on the target phone. Do not approve it on package size alone.

## Compare on the affected OnePlus phone

Use the same PDFs, retrieval results, question wording and answer length for the previous model and candidate. Include at least 20 human-reviewed questions: direct facts, numbers/dates, missing information, conflicting passages and multi-page questions. Keep document page references as ground truth.

Record cold model load time, warm time to first visible token, complete response latency, output token count, correct answers, correct claim-to-page citations, unsupported claims, empty responses and cancellation/back-button response. Repeat warm questions three times; report median and slowest observations. Test airplane mode after download. Repeat after sustained use to catch thermal slowdown.

Accept only if the improvement in latency is useful AND answer/citation correctness is acceptable for the same document questions. No invented answers to missing-information questions. A 270M model may lose accuracy: if this happens, keep the previous package or evaluate a 0.5B/0.6B alternative. CI checks integration, not semantic accuracy or device speed.

## Update path

Install the candidate APK over the existing app. Existing documents and setup completion remain. Old AI package versions must show a download requirement, not Ready. Download the new package and verify an offline answer. Interrupt and retry a download; corrupted packages must not install. Licences are available through Settings > Open Source Licenses.
