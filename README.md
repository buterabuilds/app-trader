## Project Overview

This project analyzes app records from the Apple App Store and Google Play Store, stored in two separate tables without referential integrity.

The analysis integrates inconsistent cross-platform data to compare ratings, reviews, installations, prices, genres, and categories. Business assumptions for acquisition cost, marketing expense, monthly revenue, and projected lifespan are applied to evaluate potential profitability.

## Project Objective

Develop a data-driven acquisition strategy for App Trader by answering key business questions:

- Which apps are available in both marketplaces and can be marketed under a shared budget?
- Which apps combine strong ratings with high estimated usage?
- What acquisition cost, projected lifespan, revenue, and ROI can be expected for each app?
- Which price ranges and genres offer the strongest average returns?
- How can inconsistent app names and categories be standardized across the two stores?
- Which ten apps represent the strongest acquisition opportunities based on cross-platform availability, ratings, audience size, and projected profitability?

## Technologies Used

- PostgreSQL

## Techniques and Methodology Used

- Cross-platform integration of tables without referential integrity
- Rule-based financial modeling for acquisition cost, revenue, marketing expense, lifespan, and ROI
- Name normalization and string matching for cross-store entity resolution
- Category and genre standardization using conditional classification
- Nested subqueries for reusable calculated metrics
- Set intersection to identify shared acquisition candidates
- Cross-platform aggregation of ratings and review counts
- Type conversion and normalization of inconsistent price and installation fields
- Genre-level profitability and audience segmentation
- Multi-criteria filtering and ranking for Top 10 candidate selection