# Warehouse NL-to-SQL Query Workflow

A natural-language-to-SQL workflow for a Mumbai warehouse/inventory database. Ask a plain-English question, an AI writes and safety-checks the SQL, runs it against a real database, and explains the result back in plain English — with a Flask UI.

Built primarily as a controlled comparison of 4 LLMs on the same NL-to-SQL task, to test model-selection tradeoffs (frontier vs. open-weight) independent of RAG or prompt engineering.

> This repo documents the project's design, methodology, and results. The implementation (pipeline code, prompts, eval harness, and full question/results data) is private — happy to walk through it directly.

## Architecture

Deliberately a fixed-sequence **workflow**, not an autonomous agent:

NL question → validate_question()   [deterministic]
            → generate_sql()        [AI call, model-parameterized]
            → safety_gate()         [deterministic — blocks non-read-only SQL]
            → execute_sql()         [deterministic]
            → explain_result()      [AI call, model-parameterized]

Keeping the pipeline fixed and swapping only the model isolates the model as the single variable under test. Adding agentic branching or retrieval (RAG) at this stage would introduce a second variable and break the comparison — that tradeoff is documented in the PRD.

## Data

- Scope: Mumbai region only — 5 warehouses (WH-MUM-01 to 05: Bhiwandi, Taloja, Bhandup, Kalamboli, Vashi)
- Single product category ("Beauty"), 120 SKUs across 7 subcategories
- 5 normalized tables: warehouses, products, suppliers, inventory, stock_movements (see schema.sql)
- Currency: INR, stored as plain numeric (no symbol)
- Fully synthetic, generated with a fixed random seed for reproducibility, FK-integrity verified

## Model comparison

4 models, same pipeline, only the model string swapped (via LiteLLM):

- Claude Sonnet 5 (Anthropic API) — baseline
- gpt-oss-120b (Groq)
- gpt-oss-20b (Groq)
- Llama-3.3-70B-versatile (Groq)

Scored against 40 hand-verified gold-standard questions (lookups, aggregations, joins, multi-table joins, stock-movement questions, and a safety-gate trick question), run once each — Execution Accuracy methodology: compare actual result sets, not SQL text, matching how Spider/BIRD benchmarks score.

### Results

| Model | Accuracy |
|---|---|
| Claude Sonnet 5 | 90.0% (36/40) |
| gpt-oss-120b | 87.5% (35/40) |
| gpt-oss-20b | 87.5% (35/40) |
| Llama-3.3-70B | 72.5% (29/40) |

This is a naive baseline: zero retrieval (full schema passed statically on every call) and zero clarification step — the model has to commit to an answer on the first try. Full methodology, benchmark context, and failure analysis are in the PRD.

## What's in this repo

| File | Purpose |
|---|---|
| README.md | This overview |
| schema.sql | Database schema (table structure only) |
| PRD_Final_Warehouse_Query_Workflow*.pdf | Full product requirements doc — problem framing, design decisions, methodology, findings |

Pipeline code, prompts, the 40-question eval set, and full per-question results are kept private.

## What's next

Not yet built: RAG (business-definition retrieval) and a clarification step, to test how much they close the gap versus raw model capability alone. Formal LangSmith eval, following the same pattern as a related project.
