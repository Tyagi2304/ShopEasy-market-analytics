# ShopEasy-market-analytics
# ShopEasy Marketing & Customer Experience Analytics (SQL, Python & Power BI)

An end-to-end marketing, conversion funnel, and customer sentiment analytics solution built for **ShopEasy**, an online retail business facing declining customer engagement and conversion rates despite rising marketing investments.

---

## 📋 Table of Contents
1. [Business Problem & Stakeholder Requirements](#-business-problem--stakeholder-requirements)
2. [Tech Stack & Architecture](#-tech-stack--architecture)
3. [Data Modeling: Dimension & Fact Table Breakdown](#-data-modeling-dimension--fact-table-breakdown)
4. [Data Cleaning, Enrichment & Sentiment Pipeline](#-data-cleaning-enrichment--sentiment-pipeline)
5. [Key Performance Indicators (KPIs) & Findings](#-key-performance-indicators-kpis--findings)
6. [Dashboard Walkthrough (2025 Performance)](#-dashboard-walkthrough-2025-performance)
7. [Strategic Recommendations & Action Plan](#-strategic-recommendations--action-plan)
8. [Repository Structure](#-repository-structure)

---

## 🎯 Business Problem & Stakeholder Requirements

ShopEasy launched multiple digital marketing campaigns across blog, social media, and video channels, yet observed stagnant conversion rates and falling audience engagement. Two key business stakeholders requested an analytical deep dive:

* **Marketing Manager (John Doe):** Requested an evaluation of marketing campaign ROI, content effectiveness, and funnel drop-offs across channels and product lines to understand why increased spend was not translating into higher conversions.
* **Customer Experience Manager (Jane Smith):** Requested structured sentiment analysis and rating diagnostics across customer reviews to uncover recurring product or service pain points dragging down customer satisfaction.

### Core Analytical Objectives
1. **Increase Conversion Rates:** Pinpoint funnel drop-off stages, seasonal conversion peaks/troughs, and top- vs. bottom-converting product categories.
2. **Enhance Customer Engagement:** Measure views, clicks, and likes across `BLOG`, `SOCIAL MEDIA`, and `VIDEO` content to identify high-performing formats and engagement decay.
3. **Improve Customer Feedback Scores:** Classify unstructured review text using sentiment scoring and evaluate product ratings against the **4.0 target benchmark**.

---

## 🛠️ Tech Stack & Architecture

* **SQL (T-SQL / SQL Server):** Data extraction, deduplication (`ROW_NUMBER()`), null imputation (`COALESCE` with window averages), string parsing (`CHARINDEX`, `LEFT`, `RIGHT`), and star-schema view preparation.
* **Python (Pandas, NLTK / VADER Sentiment Analysis):** Automated polarity scoring (`SentimentScore`) and sentiment categorization (`SentimentCategory` & `SentimentBucket`) across **1,363 customer reviews** (2023–2025).
* **Power BI & DAX:** Interactive 4-page executive dashboard featuring dynamic slicers (Year, Month, Product, Country, Sentiment), conversion funnel tracking, and time-series trend visuals.
* **Executive Storytelling:** Structured Business Case & Stakeholder Requirements deck alongside a Data Presentation deck translating dashboard metrics into business actions.

---

## 🗂️ Data Modeling: Dimension & Fact Table Breakdown

To support fast filtering, clean cross-table relationships, and scalable DAX calculations in Power BI, the relational source tables were structured into a **Star Schema** separating descriptive **Dimension Tables** from transactional/behavioral **Fact Tables**:

### 1. Dimension Tables (`Dim`)
| Table Name | Source Tables & SQL Logic | Key Columns | Analytical Role |
| :--- | :--- | :--- | :--- |
| **`dim_customers`** | Enriched `customers` via `LEFT JOIN` with `geography` on `GeographyID` | `CustomerID` (PK), `CustomerName`, `Email`, `Gender`, `Age`, `Country`, `City` | Enables demographic and geographic slicing (e.g., Country-level review filtering) without snowflake joins in Power BI. |
| **`dim_products`** | Transformed from `products` using a SQL `CASE` statement on `Price` | `ProductID` (PK), `ProductName`, `Price`, `PriceCategory` (`Low` < $50, `Medium` $50–$200, `High` > $200) | Standardizes the 20 sports & fitness SKUs and segments conversion/rating performance by price tier. |
| **`dim_date`** *(Calendar)* | Generated date dimension linked to `VisitDate`, `EngagementDate`, and `ReviewDate` | `Date` (PK), `Year` (2023–2025), `MonthNumber`, `MonthNameShort` (`Jan`–`Dec`) | Powers unified time-intelligence filtering across all dashboard pages and monthly trend charts. |

### 2. Fact Tables (`Fact`)
| Table Name | Source & Grain | Key Columns & Measures | Analytical Role |
| :--- | :--- | :--- | :--- |
| **`fact_customer_journey`** | Deduplicated `customer_journey` (1 row per unique customer-product-date-stage-action event) | `JourneyID` (PK), `CustomerID` (FK), `ProductID` (FK), `VisitDate` (FK), `Stage`, `Action`, `Duration` | Tracks customer progression across funnel stages (`View` → `Click` → `Drop-off` / `Purchase`) and calculates conversion rates. |
| **`fact_engagement_data`** | Cleaned `engagement_data` excluding `Newsletter` records (1 row per content campaign interaction) | `EngagementID` (PK), `ContentID`, `CampaignID`, `ProductID` (FK), `EngagementDate` (FK), `ContentType`, `Views`, `Clicks`, `Likes` | Measures top-of-funnel reach, click-through efficiency, and content format performance (`BLOG`, `SOCIAL MEDIA`, `VIDEO`). |
| **`fact_customer_reviews`** | Cleaned `customer_reviews` enriched via Python VADER sentiment (`customer_reviews_with_sentiment.csv`, 1,363 rows) | `ReviewID` (PK), `CustomerID` (FK), `ProductID` (FK), `ReviewDate` (FK), `Rating` (1–5), `ReviewText`, `SentimentScore`, `SentimentCategory`, `SentimentBucket` | Combines quantitative star ratings with NLP sentiment polarity to diagnose customer satisfaction drivers. |

---

## 🧹 Data Cleaning, Enrichment & Sentiment Pipeline

1. **Customer & Geography Denormalization (`dim_customers`):** Joined customer profiles with geographic attributes (`Country`, `City`) using a `LEFT JOIN` to preserve all customer records while enabling regional filtering.
2. **Product Price Banding (`dim_products`):** Categorized all 20 products into `Low` (< $50), `Medium` ($50–$200), and `High` (> $200) price tiers using SQL `CASE` logic.
3. **Journey Deduplication & Duration Imputation (`fact_customer_journey`):**
   * Identified and removed duplicate clickstream logs using `ROW_NUMBER() OVER (PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action ORDER BY JourneyID)`.
   * Standardized `Stage` casing (`UPPER(Stage)`) and imputed missing `Duration` values with the daily mean duration (`COALESCE(Duration, AVG(Duration) OVER (PARTITION BY VisitDate))`).
4. **Engagement Metric Parsing (`fact_engagement_data`):**
   * Split the combined `ViewsClicksCombined` string (e.g., `"1250-180"`) into separate numeric `Views` and `Clicks` columns using `LEFT`, `RIGHT`, and `CHARINDEX`.
   * Standardized `Socialmedia` labels to `SOCIAL MEDIA`, formatted `EngagementDate`, and filtered out `Newsletter` rows to focus on active digital content channels.
5. **Review Text Cleaning & Python Sentiment Scoring (`fact_customer_reviews`):**
   * Normalized double-space formatting issues in `ReviewText` via SQL `REPLACE(ReviewText, '  ', ' ')`.
   * Processed all **1,363 reviews** in Python to generate continuous `SentimentScore` values and classify feedback into 5 sentiment categories: **Positive (840)**, **Negative (226)**, **Mixed Negative (196)**, **Mixed Positive (86)**, and **Neutral (15)**.

---

## 📊 Key Performance Indicators (KPIs) & Findings

### Full-Dataset Highlights (Multi-Year Overview)
* **Overall Conversion Rate:** **8.5%** across the portfolio, peaking in **January (18.5%)**—driven by *Ski Boots*—and **September (15.7%)**, dipping to **4.3% in May** and **5.0% in October**, before rebounding to **10.2% in December**.
* **Social Media Funnel (All Years):** **2,982,369 Views** → **458,345 Clicks (15.37% CTR)** → **73,618 Likes (2.47% of views)**. While overall views declined in the second half of the year, a **15.37% CTR** shows that reached users still engage actively.
* **Customer Satisfaction:** **3.7 Average Rating** (below the **4.0 target**). Across all 1,363 reviews, **4-star (431)** and **5-star (409)** ratings lead overall volume, while **3-star (290)**, **2-star (153)**, and **1-star (80)** reviews highlight opportunities to convert mixed experiences into positive advocacy.

### 2025 Dashboard Snapshot (Filtered Year = `2025`)
1. <img width="1292" height="747" alt="Dashboard - 1" src="https://github.com/user-attachments/assets/ea61465a-15b2-4acc-8767-794d489c7f7e" />
2. <img width="1290" height="743" alt="Dashboard - 2" src="https://github.com/user-attachments/assets/54ee6369-cbca-45e5-82be-edd1089ff022" />
3. <img width="1290" height="750" alt="Dashboard - 3" src="https://github.com/user-attachments/assets/503413eb-3ec5-404d-811a-6d62df5c04a9" />
4. <img width="1291" height="746" alt="Dashboard - 4" src="https://github.com/user-attachments/assets/3010ccde-be76-401a-9d82-33f5e973e0c3" />

---

## 🖥️ Dashboard Walkthrough (2025 Performance)

1. **Executive Overview:** Unified KPI cards and trendlines combining Conversion Rate (`8.4%`), Social Media funnel (`1,096,704` views, `67,632` clicks, `4,342` likes), and Customer Reviews (`3.7` avg rating) across 20 products and 12 months.
2. **Conversion Details:** Customer journey funnel (`690 Views → 331 Clicks → 194 Drop-offs → 59 Purchases`), monthly conversion trajectory, product-by-month conversion matrix, and product conversion ranking.
3. **Social Media Details:** Funnel conversion drop-off chart, monthly views/clicks/likes trends, content type comparison (`BLOG`, `SOCIAL MEDIA`, `VIDEO`), and a product-by-month engagement heatmap matrix.
4. **Customer Review Details:** Rating distribution (`1–5` stars), sentiment category breakdown, monthly rating trends by sentiment, review-level drill-down table, and a scatter plot comparing average rating vs. review volume.

---

## 🚀 Strategic Recommendations & Action Plan

1. **Optimize Conversion Funnel & Seasonal Promotions:**
   * Double down on high-converting categories (*Kayak*, *Ski Boots*, *Climbing Rope*, *Hockey Stick*, *Surfboard*) with targeted seasonal campaigns during peak windows (January, March, and September).
   * Audit checkout and product-page friction for low-converting items (*Boxing Gloves*, *Football Helmet*, *Volleyball*) and deploy retargeting offers during historical conversion slumps (May and October).
2. **Revitalize H2 Content & Call-to-Action (CTA) Strategy:**
   * Address the H2 viewership decline (August–December) by shifting budget toward interactive short-form `VIDEO` and user-generated social content while embedding clearer product CTAs inside high-traffic `BLOG` posts.
3. **Close the Customer Satisfaction Gap (3.7 → 4.0+ Rating Target):**
   * Prioritize product quality and pricing-value fixes for SKUs rated at or below **3.5** (*Tennis Racket*, *Boxing Gloves*, *Hockey Stick*, *Golf Clubs*, *Soccer Ball*, *Surfboard*).
   * Implement an automated post-purchase follow-up workflow for `Mixed Negative` and `Negative` reviewers to resolve delivery or value concerns and encourage updated ratings.

---

## 📁 Repository Structure

```text
shopeasy-marketing-analytics/
├── README.md
├── Dashboard Screenshots/
│   ├── Dashboard - 1.png
│   ├── Dashboard - 2.png
│   ├── Dashboard - 3.png
│   └── Dashboard - 4.jpg
├── PowerBI Report/
│   ├── Dashbaord.pbix
│   └── Dashboard - 2025.pdf
│   └── Dashboard - 2024.pdf
├── Presentations/
│   ├── ShopEasy_Marketing_Analytics_Business_Case.pptx
│   └── ShopEasy_Marketing_Data_Presentation.pptx
├── Python/
│   └── ShopEasy.ipynb
├── SQL/
│   ├── dim_customers.sql
│   ├── dim_products.sql
│   ├── fact_customer_journey.sql
│   ├── fact_engagement_data.sql
│   └── fact_customer_reviews.sql
└── Data/
│   └── customer_reviews_with_sentiment.csv
│   └── MarketingAnalytics.bak
