# CiteCoach

## Model setup

CiteCoach expects an on-device model file before chat is enabled. You can use
either a hosted download URL or import a local file.

### Download via URL

Pass a download URL at build time:

```
--dart-define=MODEL_DOWNLOAD_URL=https://example.com/models/gemma-2b-it-q4.bin
```

Optional (if your file name differs from the default):

```
--dart-define=LLM_MODEL_FILE=gemma-2b-it-q4.bin
```

### Import a local file

From the setup flow or Model Info screen, choose **Import Model File** and
select the model file on device.

### Embedding model (optional)

If you ship a separate embedding model file, set:

```
--dart-define=EMBEDDING_MODEL_FILE=tinybert-embedding.bin
```