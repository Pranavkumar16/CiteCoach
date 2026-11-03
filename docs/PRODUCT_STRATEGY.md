# CiteCoach Product Strategy

## Product direction

**Category:** Evidence Intelligence Platform  
**Primary audiences:** University students, postgraduate researchers and knowledge workers  
**Core promise:** CiteCoach does not merely summarise documents. It helps users inspect, compare and verify what their information actually supports.

**Brand:** CiteCoach  
**Tagline:** Every answer. Backed by evidence.  
**Visual identity:** Ink & Signal — Oxblood Ink, Warm Parchment, Acid Citron and Signal Vermilion.

## Flagship differentiator: Challenge My Answer

The flagship workflow is claim-level evidence review.

For each material claim in an answer, CiteCoach should:
- Locate supporting passages across the selected document collection.
- Locate passages that contradict or qualify the claim.
- Distinguish Supported, Contradicted, Partially supported and Insufficient evidence.
- Show precise source references and open the source location.
- Avoid presenting model confidence as factual proof.
- Abstain when retrieved evidence is insufficient or ambiguous.

A citation should only be labelled supporting when the cited passage actually entails or materially supports the claim. The system should separately record retrieval coverage, citation correctness and answer correctness.

## Product pillars

1. **Ask:** Ask questions across selected documents and collections.
2. **Verify:** Challenge claims and inspect supporting, contradicting and missing evidence.
3. **Compare:** Compare document versions, policies, reports, quotations and research findings.
4. **Learn:** Turn verified material into explanations, flashcards and practice questions.

## Roadmap

### Phase 0 — Foundation and reliability
- Stabilise Android and iOS local inference.
- Complete local semantic retrieval and hybrid retrieval integration.
- Validate page-level citations end to end.
- Complete OCR fallback for scanned PDFs.
- Establish offline network-traffic and privacy tests.
- Add a repeatable evaluation dataset and baseline report.

### Phase 1 — Evidence-first answers
- Define a claim extraction schema.
- Retrieve evidence per claim, not only per whole answer.
- Add claim-level support and contradiction evaluation.
- Add an insufficient-evidence outcome and safe abstention.
- Link each claim to the exact source page/passage.
- Build an evaluation report for answer correctness, evidence precision, citation accuracy and unsupported-claim rate.

### Phase 2 — Document intelligence
- Compare document versions.
- Extract structured fields and tables with source references.
- Compare information across multiple documents.
- Identify conflicting values, dates, obligations and statements.

### Phase 3 — Personal learning
- Generate flashcards and question papers from selected sources.
- Explain concepts at beginner, intermediate and advanced levels.
- Track learning gaps based on quiz outcomes.
- Keep generated learning content linked to its source material.

## MVP scope

The first differentiated release should focus on:
1. Import and index a small collection of PDFs locally.
2. Ask a question across those documents.
3. Generate an answer with precise source references.
4. Break the answer into material claims.
5. Show evidence supporting or contradicting each claim.
6. State when evidence is insufficient.
7. Work offline after required model assets are installed.

Do not build all four product pillars simultaneously. Prove the evidence workflow first.

## Evaluation requirements

Maintain a curated, versioned benchmark containing:
- Direct factual questions.
- Multi-hop questions requiring multiple passages.
- Questions with contradictory source passages.
- Questions where the documents contain no answer.
- Tables, figures and scanned-document cases.

Report separately:
- Answer correctness.
- Evidence retrieval recall and precision.
- Claim-level support/contradiction classification.
- Citation-to-claim entailment accuracy.
- Unsupported-claim rate.
- Abstention precision and recall.
- Latency, peak memory and battery impact by device tier.

Use human-reviewed ground truth for the benchmark. LLM-as-judge can assist evaluation but should not be the only ground truth.

## Product principles

- Evidence before eloquence.
- Be explicit about uncertainty.
- No fabricated or decorative citations.
- Keep local processing local when offline mode is selected.
- Make source verification a first-class interaction.
- Do not claim complete privacy or offline capability beyond what tests establish.

## Release decision

A feature is not ready simply because it produces a plausible answer. Evidence workflows must pass a documented benchmark and device validation before being described as reliable in product copy.
