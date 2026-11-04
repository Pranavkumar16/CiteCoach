# CiteCoach model selection — 4 November 2026

## Decision

Use **Qwen3 1.7B Instruct, Q4_K_M, with thinking explicitly disabled** as the next candidate default, replacing the proposed Gemma change. It was the only tested candidate to answer all 20 factual checks correctly. Do not describe it as a proven production model or a major speed improvement. On this host its median response time was essentially the same as the existing Qwen 2.5 1.5B model. The much faster tiny candidates lost too much answer/citation reliability.

Keep the product name **CiteCoach AI**. Model attribution belongs in the legal notices. The package is about 1.03 GiB, comparable to the baseline GGUF, not the previously proposed 242 MiB Gemma package.

## Actual local inference results

| Candidate, all Q4_K_M | Factual checks correct | Missing-answer abstentions correct | Median first text | Median total response |
|---|---:|---:|---:|---:|
| Gemma 3 270M IT | 7/20 | 0/4 | 0.78 s | 0.96 s |
| Qwen 2.5 0.5B Instruct | 9/20 | 2/4 | 2.42 s | 2.86 s |
| Qwen3 0.6B, thinking off | 15/20 | 4/4 | 1.81 s | 2.19 s |
| Qwen 2.5 1.5B Instruct baseline | 16/20 | 4/4 | 4.53 s | 5.31 s |
| **Qwen3 1.7B, thinking off** | **20/20** | **4/4** | **4.66 s** | **5.36 s** |

These are measurements on an AMD EPYC 9V74 x86_64 host, not the user's phone. They do not establish Android latency, thermal behaviour, battery use or crash freedom. Cold loading is excluded from per-answer timings; server startup observations are preserved separately. No model was run concurrently with another model.

## Method and limits

- A small, synthetic six-page agreement fixture with 20 fixed questions and explicit reference answers/pages. It contains direct facts, standard-versus-exception payment terms, a superseding amendment, two arithmetic questions, and four missing-information questions.
- All models saw the same complete excerpts and questions; only their required prompt wrapper differed. This tests answering from supplied evidence, not PDF parsing, OCR, retrieval recall or real-world document quality. It is not an independent published benchmark.
- One answer per unique question plus repeats of the first five questions for latency variation: 25 requests per model, 125 total. Quality scores use only the first 20. Models were evaluated in a fixed order with one fixed seed; no uncertainty interval is claimed.
- llama.cpp revision `149f5641b931aaf33697d70f9abc90c3e5300247`, CPU only, 4 generation/batch threads, context 2048, batch/microbatch 256, max output 192, temperature 0.3, top-p 0.9, top-k 40, repeat penalty 1.1, seed 42, prompt caching off. Exact model revisions, SHA-256 hashes, raw answers, token timings and startup times are saved under `scripts/model_eval/results/`.
- The server runtime approximates the app's CPU inference configuration; it does not test the Android JNI bridge and its exact sampler chain. UI and retrieval overhead are excluded.
- Answers were reviewed against the fixture by the assistant. A factual pass requires the requested information, with no material contradiction; missing information must be acknowledged. No partial credit. These are assistant-reviewed checks, not external human review or automatically verified semantic entailment.

## Citation review and important failures

Factual scores above do **not** mean all citations are complete or correct. Gemma omitted citations throughout and invented Singapore server hosting, AES-256 encryption, annual revenue and a refund percentage. Qwen 0.5B sometimes returned only a page label or an irrelevant passage. Qwen3 0.6B confused standard payment terms with the exception and cited incorrect pages for the customer, contact and cancellation notice; it also failed the fee-per-user calculation. The baseline missed export formats and fee-per-user calculation, failed to total the budget, and added a misleading explanation for the customer contact.

Qwen3 1.7B cited the right pages for direct answers and correctly abstained on all four missing-information questions. Its unchanged-training answer cited Page 4 for the eight hours but omitted Page 5, which establishes that the amendment leaves the other terms unchanged. This is incomplete evidence coverage even though the final answer is correct. Further citation/entailment testing is required. The application must not invent citation badges for an answer that did not cite an excerpt; that fallback is removed in this change.

## Before release

1. Require CI tests and APK compilation on the final candidate commit.
2. Test installation over the previous version: documents stay available, the old package is not reported ready, and the new package can be downloaded and verified.
3. On the affected OnePlus, repeat the same questions and record cold load time, warm first-token and total latency. Test cancellation, back navigation, airplane mode and sustained use.
4. Extend to at least 50 representative real-document questions with human-reviewed answers and claim-to-page citations. Evaluate PDFs with tables, contradictions and missing information. Reconsider the default if latency or evidence accuracy is unacceptable.

To reproduce, build llama-server at the revision above, download the five pinned GGUF files in the manifests, and run `python scripts/model_eval/run.py --server /path/llama-server --models /path/models --output results.json --only gemma270m,qwen05b,qwen3,qwen15b,qwen3_17b`. Name the files and manifests as shown by the saved results. The script records raw answers; factual scoring requires review against cases.json.
