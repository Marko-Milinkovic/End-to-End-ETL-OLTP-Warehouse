End‑to‑End ETL OLTP Warehouse for Retail Sales & Customer Reviews 

An end-to-end data warehousing project for an online article sales system.
The pipeline covers everything from the operational database, through ETL into a star-schema warehouse, to analytical MDX queries.

---

## Project Structure

```
├── 1_script_for_oltp_creation.sql        OLTP schema
├── 2_script_for_mockdata_insertion.sql    Initial OLTP data (10+ rows per table)
├── 3_script_for_warehouse_creation.sql    Warehouse star schema
├── 4_script_for_additional_mockdata.sql   Extra data for incremental load testing
├── loading/                              ETL folder (Kettle files)
│   ├── load_dim_time.ktr
│   ├── load_dim_place.ktr
│   ├── load_dim_seller.ktr
│   ├── load_dim_article.ktr
│   ├── load_fact_sales.ktr
│   ├── load_fact_reviews.ktr
│   └── global_loading_job.kjb
├── warehouse.xml                          Mondrian schema definition
├── querries-mdx.txt                          MDX analytical queries
└── README.md
```

---

## 1. OLTP Database

The operational database (`oltp`) models an online marketplace where users buy and sell articles.

```
MESTO ─────────┐
(Place)        │
               ▼
KORISNIK ──► buys/sells
(User)     │
           ├──► ARTIKAL ◄── KATEGORIJA
           │    (Article)    (Category)
           │
           ├──► NARUDZBINA ──► STAVKA
           │    (Order)        (Order item)
           │
           ├──► KORPA
           │    (Cart)
           │
           └──► RECENZIJA
                (Review)
```

**Key design detail:** Every table has a `CreatedAt` column. This is the timestamp that the ETL process uses to determine which rows are new since the last load, enabling incremental loading.

---

## 2. Warehouse (Star Schema)

The warehouse (`warehouse`) is designed as a **star schema** to support two analytical areas:

1. **Sales analysis** -- quantity and amount by category, time, gender, age group, buyer place, seller place
2. **Review analysis** -- count and rating by time, article, seller, gender, age group, buyer place, seller place

```
                    DIM_TIME
                       │
          DIM_GENDER   │   DIM_AGE_GROUP
               │       │       │
               └───┐   │   ┌───┘
                   ▼   ▼   ▼
DIM_PLACE ──► FACT_SALES ◄── DIM_ARTICLE
(buyer)        (seller) ◄── DIM_PLACE


          DIM_GENDER   DIM_TIME   DIM_AGE_GROUP
               │          │           │
               └───┐      │      ┌────┘
                   ▼      ▼      ▼
DIM_PLACE ──► FACT_REVIEWS ◄── DIM_ARTICLE
(buyer)        │    (seller) ◄── DIM_PLACE
               │
               ▼
          DIM_SELLER
```

**Fact tables:**

| Fact Table | Grain | Measures |
|------------|-------|----------|
| `FACT_SALES` | One order item (one `STAVKA` row) | `QuantitySold`, `SalesAmount` |
| `FACT_REVIEWS` | One review (one `RECENZIJA` row) | `ReviewCount`, `Rating`, `MinRating`, `MaxRating` |

**Dimension tables:**

| Dimension | Source | Role |
|-----------|--------|------|
| `DIM_TIME` | Dates from orders and reviews | Calendar hierarchy (Year > Quarter > Month > Day) |
| `DIM_ARTICLE` | `ARTIKAL` + `KATEGORIJA` + seller `KORISNIK` | Denormalized: Category > Article |
| `DIM_GENDER` | Static (M/Z/Unknown) | Buyer gender |
| `DIM_AGE_GROUP` | Static age brackets | Buyer age group |
| `DIM_PLACE` | `MESTO` | Role-playing: buyer place and seller place |
| `DIM_SELLER` | `KORISNIK` (sellers only) | Seller identity |

Each dimension has an **Unknown row** (key = 0) to handle missing lookups gracefully.

**ETL Control:**

The `ETL_CONTROL` table tracks the last successful load timestamp for each process. This is the mechanism that distinguishes total from incremental loading.

---

## 3. ETL Transformations

All transformations are built in **Pentaho Data Integration (Kettle)** and follow the same conceptual pattern:

```
┌─────────────────┐
│  Read ETL_CONTROL│  ← Get LastSuccessfulLoad for this process
│  (get_last_load) │     NULL on first run = total load
└────────┬────────┘
         │ passes timestamp
         ▼
┌─────────────────┐
│  Extract from    │  ← SQL with WHERE CreatedAt > ?
│  OLTP            │     First run: all rows; later: only new rows
└────────┬────────┘
         │ source rows
         ▼
┌─────────────────┐
│  Load into       │  ← Insert new rows into warehouse
│  Warehouse       │     (lookup/filter or insert-update)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Update          │  ← Mark ETL_CONTROL as SUCCESS
│  ETL_CONTROL     │     with current timestamp
└─────────────────┘
```

### Dimension Transformations

**load_dim_time**

```
get_last_load ──► extract_dates ──► insert_update_dim_time ──► update_etl_control
```

Extracts distinct dates from `NARUDZBINA.Datum` and `RECENZIJA.Datum`. The SQL computes all calendar attributes (day, month name, quarter, year, weekday, weekend flag). Uses Insert/Update with insert-only logic (no updates on existing dates).

**load_dim_place**

```
get_last_load ──► extract_places ──► insert_update_dim_place ──► update_etl_control
```

Loads places from `MESTO`. Uses Insert/Update with SCD Type 1 logic -- if `PlaceName` changes in the source, it gets updated in the warehouse.

**load_dim_seller**

```
get_last_load ──► extract_sellers ──► insert_update_dim_seller ──► update_etl_control
```

Joins `ARTIKAL` + `KORISNIK` + `MESTO` to identify sellers. Uses Insert/Update with insert-only logic (new sellers are added, existing ones are not modified).

**load_dim_article**

```
get_last_load ──► extract_articles ──► lookup_dim_article ──► filter_new_only ──► insert_dim_article ──► update_etl_control
```

Joins `ARTIKAL` + `KATEGORIJA` + `KORISNIK`. Uses a different pattern: Database Lookup checks if the article already exists, Filter Rows keeps only new ones, Table Output inserts them. This is insert-only (no SCD).

### Fact Transformations

**load_fact_sales**

```
get_last_load ──► extract_sales ──► lookup_time ──► lookup_article ──► lookup_gender
    ──► lookup_age_group ──► lookup_buyer_place ──► lookup_seller_place
    ──► lookup_fact_exists ──► filter_new_only ──► insert_fact_sales ──► update_etl_control
```

Joins `STAVKA` + `NARUDZBINA` + `ARTIKAL` + buyer/seller `KORISNIK`. Then six Database Lookup steps translate business values into warehouse surrogate keys. A final lookup + filter ensures no duplicate fact rows are inserted.

**load_fact_reviews**

```
get_last_load ──► extract_reviews ──► lookup_time ──► lookup_article ──► lookup_seller
    ──► lookup_gender ──► lookup_age_group ──► lookup_buyer_place ──► lookup_seller_place
    ──► lookup_fact_exists ──► filter_new_only ──► insert_fact_reviews ──► update_etl_control
```

Same pattern as sales. Joins `RECENZIJA` + `ARTIKAL` + reviewer/seller `KORISNIK`. Seven dimension lookups resolve surrogate keys. Deduplication by composite key `(SourceReviewerID, SourceArticleID, ReviewDate, ReviewTime)`.

---

## 4. Job Orchestration

The `global_loading_job.kjb` runs all six transformations in the correct order:

```
START
  │
  ▼
Load DIM_TIME ──── failure ──► mark FAILED ──► ABORT
  │ success
  ▼
Load DIM_PLACE ─── failure ──► mark FAILED ──► ABORT
  │ success
  ▼
Load DIM_SELLER ── failure ──► mark FAILED ──► ABORT
  │ success
  ▼
Load DIM_ARTICLE ─ failure ──► mark FAILED ──► ABORT
  │ success
  ▼
Load FACT_SALES ── failure ──► mark FAILED ──► ABORT
  │ success
  ▼
Load FACT_REVIEWS ─ failure ──► mark FAILED ──► ABORT
  │ success
  ▼
SUCCESS
```

**Order matters:** Dimensions must be loaded before facts, because fact rows need to look up dimension surrogate keys. If any transformation fails, the job updates `ETL_CONTROL` with `FAILED` status and aborts immediately.

---

## 5. Total vs. Incremental Loading

| Scenario | ETL_CONTROL.LastSuccessfulLoad | Behavior |
|----------|-------------------------------|----------|
| **First run (total)** | `NULL` | Defaults to `1900-01-01`, so `CreatedAt > 1900-01-01` matches all rows |
| **Subsequent runs (incremental)** | Previous run timestamp | `CreatedAt > LastSuccessfulLoad` matches only newly inserted rows |

**Testing incremental loading:**

1. Run `2_script_for_mockdata_insertion.sql` to populate OLTP with initial data
2. Run the job -- all rows are loaded (total load)
3. Run `4_script_for_additional_mockdata.sql` to add new OLTP data
4. Run the job again -- only the new rows are loaded (incremental load)

The second run processes only the delta (new places, new sellers, new articles, new orders, new reviews), proving that the incremental mechanism works.

---

## 6. Mondrian Schema and MDX Queries

### skladiste.xml

The Mondrian schema definition connects the warehouse tables to an OLAP logical model. It maps the physical star schema to cubes that MDX queries can be executed against.

```
┌─────────────────────────────────┐
│        skladiste.xml            │
│                                 │
│  Cube: Prodaja (FACT_SALES)     │
│    ├── Vreme      → dim_time    │
│    ├── Artikal    → dim_article │
│    ├── Pol        → dim_gender  │
│    ├── Uzrast     → dim_age_group│
│    ├── Mesto kupca → dim_place  │
│    └── Mesto prodavca → dim_place│
│                                 │
│  Cube: Recenzije (FACT_REVIEWS) │
│    ├── Vreme      → dim_time    │
│    ├── Artikal    → dim_article │
│    ├── Prodavac   → dim_seller  │
│    ├── Pol        → dim_gender  │
│    ├── Uzrast     → dim_age_group│
│    ├── Mesto kupca → dim_place  │
│    └── Mesto prodavca → dim_place│
└─────────────────────────────────┘
```

`DIM_PLACE` is a **role-playing dimension** -- the same physical table appears as both "Mesto kupca" (buyer place) and "Mesto prodavca" (seller place), each linked through a different foreign key.

### MDX Queries (upiti-mdx.txt)

Five analytical queries are defined, each answering a specific business question:

| Query | Question | Cube | Measure | Grouped By |
|-------|----------|------|---------|------------|
| **a** | Sales amount by category and year | Prodaja | Iznos prodaje | Kategorija x Godina |
| **b** | Quantity sold by seller place | Prodaja | Broj prodatih artikala | Mesto prodavca |
| **c** | Number of reviews by month | Recenzije | Broj recenzija | Mesec |
| **d** | Average rating by category and seller place | Recenzije | Prosecna ocena | Kategorija x Mesto prodavca |
| **e** | Min and max rating by seller | Recenzije | Minimalna/Maksimalna ocena | Prodavac |

These queries are executed in Mondrian Schema Workbench's MDX query window, which reads `skladiste.xml`, connects to the `warehouse` database, and returns the analytical results.

---

## End-to-End Pipeline

```
OLTP Database                    Warehouse                      Analytics
─────────────                    ─────────                      ─────────

1_script_for_oltp_creation.sql
         │
         ▼
2_script_for_mockdata_insertion.sql
         │                    3_script_for_warehouse_creation.sql
         │                              │
         ▼                              ▼
   ┌──────────┐                  ┌────────────┐
   │   oltp   │ ── Kettle ETL ──►│  warehouse │
   │ database │    (punjenje/)   │  database  │
   └──────────┘                  └─────┬──────┘
         │                              │
         ▼                              ▼
4_script_for_additional_mockdata.sql   skladiste.xml
  (incremental test)                    │
         │                              ▼
         └──── Kettle ETL ────►  upiti-mdx.txt
               (only new rows)   (analytical queries)
```
