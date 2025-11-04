# RadarSci

RadarSci, a radar for scientific literature, is a Typer-powered CLI that keeps laboratory teams up to date with the latest, most relevant papers from the journals they care about. It queries the Europe PMC literature service for the chosen journals, scores candidates using the supplied keywords, and renders either a sleek terminal table or a minimalist HTML report with clickable cards.

## Requirements

- [pixi](https://pixi.sh) 0.48 or newer (dependency manager)

All runtime dependencies are specified in `pixi.toml`. No `pip` steps required.

## Quick start

```bash
# Solve the environment once
pixi install

# Show usage information
pixi run radarsci --help

# Scan the default journals with a 30-day window and CLI output
pixi run radarsci
```

## Example outputs

```text
$ pixi run radarsci --keyword metagenomics --journal "Nature Microbiology" --limit 2 --days 30

RadarSci — a radar for scientific literature
✦ Keywords: "metagenomics"                  ✦ Days window: last 30 days
✦ Limit: 2                                  ✦ Sort: Score
✦ Coverage: All                             ✦ Journals searched (1) [Nature Microbiology]

Coverage: Full (all 1 keyword matched)

Journal             Date                  Score   Days ago   Title
Nature Microbiology Wednesday, 2025-10-22 18.69   13         Long-read metagenomics for strain tracking after faecal microbiota transplant.
Nature Microbiology Thursday, 2025-10-30  12.17   5          Human immunodeficiency virus and antiretroviral therapies exert distinct influences across diverse gut microbiomes.
```

Generate the exact same search as a neon HTML report (keywords and journal included) with:

```bash
pixi run radarsci \
  --keyword metagenomics \
  --journal "Nature Microbiology" \
  --limit 2 \
  --days 30 \
  --format web \
  --output outputs/metagenomics.html
```

Peek at the neon HTML cards by opening [docs/examples/report-preview.html](https://raw.githubusercontent.com/juanvillada/radarsci/main/docs/examples/report-preview.html) in a browser—the bundled sample shows an end-to-end report with clickable DOI links and radar scores. The cards look like:

> **HTML report sneak peek**
> - Journal: Trends in Microbiology
> - Date: Tuesday, 2025-10-28
> - Days ago: 7
> - RadarSci score: 22.60
> - Authors: Tabugo SR.
> - Summary: Mangroves are known worldwide but their concealed network of microbiomes is poorly understood...

## Container image

### Docker usage

**Build & tag**

```bash
# build from the local checkout
docker build -t astrogenomics/radarsci:dev .

# run the CLI help locally
docker run --rm -it astrogenomics/radarsci:dev --help
```

**Run searches**

```bash
# CLI output (non-interactive runs default to 244 cols; override with RADARSCI_CONSOLE_WIDTH)
docker run --rm astrogenomics/radarsci:dev --keyword "gut microbiome" --journal all --limit 10

# Generate an HTML report and persist it on the host
docker run --rm \
  -v "$(pwd)/outputs:/app/outputs" \
  astrogenomics/radarsci:dev \
  --keyword metagenomics \
  --journal "Nature Microbiology" \
  --limit 5 \
  --format web \
  --output outputs/metagenomics.html
```

**Publish to Docker Hub**

```bash
# authenticate once (or rely on CI secrets)
docker login -u astrogenomics

# tag the dev build for release and push
docker tag astrogenomics/radarsci:dev astrogenomics/radarsci:v0.2.0
docker tag astrogenomics/radarsci:dev astrogenomics/radarsci:latest
docker push astrogenomics/radarsci:v0.2.0
docker push astrogenomics/radarsci:latest

# external users: pull and run from Docker Hub
docker pull astrogenomics/radarsci:latest
docker run --rm astrogenomics/radarsci --keyword "gut microbiome" --journal all --limit 10
docker run --rm \
  -v "$(pwd)/outputs:/app/outputs" \
  astrogenomics/radarsci \
  --keyword metagenomics \
  --journal "Nature Microbiology" \
  --limit 5 \
  --format web \
  --output outputs/metagenomics.html
```

GitHub releases automatically push multi-arch tags (`latest`, `vX.Y.Z`) via `.github/workflows/container-release.yml`. For one-off experiments, swap in your own namespace:

```bash
docker buildx build --push \
  --platform linux/amd64,linux/arm64 \
  --tag yourhandle/radarsci:pr123 .
```

## Custom searches

- Add more keywords by repeating `--keyword/-k`.
- Choose journals by repeating `--journal/-j` with either the predefined keys (see table below) or any journal title recognised by Europe PMC (e.g. `"The ISME Journal"`).
- Use `--journal all` to include every built-in journal in a single run.
- Control freshness with `--days/-d` (0 disables the date filter).
- Choose the ordering strategy with `--sort` (`score`, `recency`, or `journal`).
- Trim the list with `--limit/-n`.
- Generate a minimalist HTML report with `--format web --output path/to/report.html`.
- Results always include the requested keywords; papers with zero keyword matches are filtered out automatically.
- Use `--coverage full` when you only want papers that match every keyword.
- Use `--skip-journal/-skip` to exclude specific journals (handy with `--journal all`).
- Add `--include-preprints` to pull in arXiv and bioRxiv alongside the selected journals (including `--journal all`). You can also target them directly with `--journal arxiv` or `--journal biorxiv`.

Example:

```bash
pixi run radarsci \
  --keyword metagenomics \
  --journal nature-microbiology \
  --journal cell-systems \
  --limit 10 \
  --days 60 \
  --format web \
  --output outputs/metagenomics.html
```

All built-in journals in one go:

```bash
pixi run radarsci \
  --keyword metagenomics \
  --journal all \
  --limit 10 \
  --days 20 \
  --sort score \
  --coverage all \
  --format web \
  --output outputs/metagenomics.html
```

All journals plus the preprint servers for a specific topic:

```bash
pixi run radarsci \
  --keyword "gut microbiome" \
  --journal all \
  --include-preprints \
  --limit 10 \
  --days 10
```

## CLI options at a glance

| Option | Description |
| --- | --- |
| `--keyword/-k TEXT` | Add one or more search keywords (repeatable). |
| `--journal/-j TEXT` | Restrict to a journal key/name (repeatable). Use `all` to scan every built-in journal. |
| `--limit/-n INT` | Maximum number of results to include (default 12). |
| `--days/-d INT` | Only include papers published in the last N days; `0` disables the cutoff. |
| `--sort TEXT` | Sorting mode: `score` (default), `recency`, or `journal`. |
| `--coverage TEXT` | Coverage filter: `all` (default) shows every match level; `full` keeps only full keyword matches. |
| `--format TEXT` | Output mode: `cli` (default) or `web`. |
| `--skip-journal/-skip TEXT` | Exclude a journal key/name from the search (repeatable). |
| `--output PATH` | Destination for the HTML report; omit to auto-generate a timestamped file. |
| `--include-preprints` | Add arXiv and bioRxiv to the selected journals (including `--journal all`). |

## Built-in journal keywords

| Journal                            | CLI key                             | Container title                |
|------------------------------------|-------------------------------------|--------------------------------|
| Cell                               | `cell`                              | Cell                           |
| Cell Genomics                      | `cell-genomics`                     | Cell Genomics                  |
| Cell Host & Microbe                | `cell-host-microbe`                 | Cell Host & Microbe            |
| Cell Metabolism                    | `cell-metabolism`                   | Cell Metabolism                |
| Cell Reports                       | `cell-reports`                      | Cell Reports                   |
| Cell Systems                       | `cell-systems`                      | Cell Systems                   |
| Communications Biology             | `communications-biology`            | Communications Biology         |
| Current Biology                    | `current-biology`                   | Current Biology                |
| ISME Communications                | `isme-communications`               | ISME Communications            |
| mBio                               | `mbio`                              | mBio                           |
| Molecular Biology and Evolution    | `molecular-biology-and-evolution`   | Molecular Biology and Evolution |
| mSystems                           | `msystems`                          | mSystems                       |
| Nature                             | `nature`                            | Nature                         |
| Nature Biotechnology               | `nature-biotechnology`              | Nature Biotechnology           |
| Nature Communications              | `nature-communications`             | Nature Communications          |
| Nature Ecology & Evolution         | `nature-ecology-evolution`          | Nature Ecology & Evolution     |
| Nature Machine Intelligence        | `nature-machine-intelligence`       | Nature Machine Intelligence    |
| Nature Methods                     | `nature-methods`                    | Nature Methods                 |
| Nature Microbiology                | `nature-microbiology`               | Nature Microbiology            |
| Nature Reviews Microbiology        | `nature-reviews-microbiology`       | Nature Reviews Microbiology    |
| Science                            | `science`                           | Science                        |
| Science Advances                   | `science-advances`                  | Science Advances               |
| The ISME Journal                   | `the-isme-journal`                  | The ISME Journal               |
| Trends in Biotechnology            | `trends-in-biotechnology`           | Trends in Biotechnology        |
| Trends in Ecology & Evolution      | `trends-in-ecology-evolution`       | Trends in Ecology & Evolution  |
| Trends in Microbiology             | `trends-in-microbiology`            | Trends in Microbiology         |

Optional preprint sources (enabled with `--include-preprints` or by specifying them explicitly):

| Preprint server | CLI key  | Container title |
|-----------------|----------|-----------------|
| arXiv           | `arxiv`  | arXiv           |
| bioRxiv         | `biorxiv`| bioRxiv         |

Preprint lookups are still backed by the Europe PMC API, using the publisher feed to respect your `--days` window.

## How relevance works

RadarSci blends three signals for each returned article:

1. Keyword density, with extra weight when terms appear in the title or abstract.
2. Europe PMC's relevance score for the underlying query.
3. A recency boost that depends on how many days ago the work was published.

The precise scoring function is:

```
S = 6 * T + 2.5 * B + 4 * M + (R / 10) + 6 * F + 4 / (1 + D)
```

Where:

- `T` = number of keyword hits in the title.
- `B` = number of keyword hits in the title + abstract (case-insensitive).
- `M` = number of distinct query keywords that appear at least once.
- `R` = Europe PMC relevance score from the API response (0 when unavailable).
- `D` = days since publication (0 for same-day releases; if unknown, the recency terms are omitted).
- `F` = max(0, 1 - min(D, W) / W) with `W = max(requested_days, 30)` - a freshness factor bounded between 0 and 1.

The final score is rounded to two decimals. Scores and the associated `D` ("days ago") are displayed in both the CLI and HTML reports.

By default, RadarSci sorts by decreasing score and, within ties, by increasing `D`. Use `--sort recency` to prioritise fresher items or `--sort journal` to group by journal name.

Articles are grouped per journal and interleaved to guarantee that every requested journal is represented before the overall limit is reached. Remaining slots (if any) are backfilled by the highest-scoring papers regardless of journal.

## Data source

- RadarSci uses the [Europe PMC REST API](https://europepmc.org/RestfulWebService) to perform `(keyword1 OR keyword2 ...) AND JOURNAL:"name"` searches with an optional publication date window.
- Returned metadata (title, authors, abstract, DOI, relevance score) is normalised and stored locally in memory only.
- Europe PMC requires no API keys, but we ship a descriptive `User-Agent` so that traffic is easy to attribute.

## Project layout

- `src/radarsci/cli.py` - Typer command definition and orchestration.
- `src/radarsci/fetcher.py` - Europe PMC queries and response normalisation.
- `src/radarsci/relevance.py` - Relevance scoring heuristics.
- `src/radarsci/reporting.py` - Rich terminal table and HTML rendering.
- `pixi.toml` - Environment + task configuration.

## Notes

- The CLI uses a rich progress bar while contacting Europe PMC; network access is required.
- HTML reports are self-contained and easy to share.
- The project stays Python-only for maximum portability. Contributions are welcome!

## Contact

For questions or feedback, reach out to Juan at juanv@linux.com
