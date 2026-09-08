-- App Trader purchases apps up to $2.50 for 25000 then (10000 * price)
-- --> app price is determind by the highest app price between stores

-- Apps earn $5000 / month per store

-- App marketing costs $1000 / month regardless of how many stores it's on (apps listed on both store preferred to save on marketing)

-- App projected lifespan is extended 1 year for every half point gained in rating

----------------------------------------->
-- Client Needs:

-- Apps that are listed on both stores
SELECT DISTINCT name
FROM app_store_apps
	INNER JOIN play_store_apps USING (name);

-- Apps with better ratings and higher usage
SELECT name, 
	rating, 
	review_count, 
	review_count::numeric * 100 AS est_downloads
FROM app_store_apps
WHERE rating >= 3.5
ORDER BY est_downloads DESC;

SELECT name,
	MAX(rating) AS rating,
	MAX(review_count) AS review_count,
	MAX(review_count::numeric * 100) AS est_downloads,
	MAX(REPLACE(REPLACE(install_count, '+', ''), ',', '')::numeric) AS install_count
FROM play_store_apps
WHERE rating >= 3.5
GROUP BY name
ORDER BY install_count DESC, est_downloads DESC;

-- Queries for calculating lifespan, downloads, app_cost, marketing_cost, and est_revenue
SELECT *,
	ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
	review_count::numeric * 100 AS est_downloads,
	CASE WHEN price <= 2.5 THEN 25000
		ELSE (price * 10000)::integer END AS app_cost,
	(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
	(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
FROM app_store_apps
WHERE rating > 0;

SELECT *,
	ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
	REPLACE(REPLACE(install_count, '+', ''), ',', '')::numeric AS est_downloads,
	CASE WHEN price::money::numeric <= 2.5 THEN 25000
		ELSE (price::money::numeric * 10000)::integer END AS app_cost,
	(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
	(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
FROM play_store_apps;

-- Apps that have higher ROI based on projected lifespan
SELECT name,
	rating,
	primary_genre,
	est_downloads,
	est_revenue - marketing_cost - app_cost AS ROI
FROM (SELECT *,
		ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
		review_count::numeric * 100 AS est_downloads,
		CASE WHEN price <= 2.5 THEN 25000
			ELSE (price * 10000)::integer END AS app_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
	FROM app_store_apps
	WHERE rating > 0) AS app_store
WHERE est_downloads > 10000 AND (est_revenue - marketing_cost - app_cost) > 0
ORDER BY ROI DESC;

SELECT DISTINCT name,
	rating,
	split_part(genres,';',1) as primary_genre,
	est_downloads,
	est_revenue - marketing_cost - app_cost AS ROI
FROM (SELECT *,
		ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
		REPLACE(REPLACE(install_count, '+', ''), ',', '')::numeric AS est_downloads,
		CASE WHEN price::money::numeric <= 2.5 THEN 25000
			ELSE (price::money::numeric * 10000)::integer END AS app_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
	FROM play_store_apps) AS play_store
WHERE est_downloads > 10000 AND (est_revenue - marketing_cost - app_cost) > 0
ORDER BY ROI DESC;

-- Top app categories for each store
SELECT 
	primary_genre,
	ROUND(AVG(est_downloads), 2) AS avg_downloads,
	ROUND(AVG(est_revenue - marketing_cost - app_cost), 2) AS avg_roi
FROM (SELECT *,
		ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
		review_count::numeric * 100 AS est_downloads,
		CASE WHEN price <= 2.5 THEN 25000
			ELSE (price * 10000)::integer END AS app_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
	FROM app_store_apps
	WHERE rating > 0) AS app_store
GROUP BY primary_genre
ORDER BY avg_roi DESC;

SELECT
	category,
	ROUND(AVG(est_downloads), 2) AS avg_downloads,
	ROUND(AVG(est_revenue - marketing_cost - app_cost), 2) AS avg_roi
FROM (SELECT *,
		ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
		REPLACE(REPLACE(install_count, '+', ''), ',', '')::numeric AS est_downloads,
		CASE WHEN price::money::numeric <= 2.5 THEN 25000
			ELSE (price::money::numeric * 10000)::integer END AS app_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
	FROM play_store_apps) AS play_store
GROUP BY category
ORDER BY avg_roi DESC;

-- Apps in both stores
SELECT DISTINCT app.name,
	play.name,
	primary_genre,
	category
FROM app_store_apps AS app
	INNER JOIN play_store_apps AS play ON app.name LIKE '%' || play.name || '%'
WHERE LENGTH(play.name) > 2;

SELECT DISTINCT play.name,
	app.name,
	primary_genre,
	category
FROM play_store_apps AS play
	INNER JOIN app_store_apps AS app ON play.name LIKE '%' || app.name || '%';

-- Cleaning names to get consistent app names
SELECT DISTINCT name
FROM (SELECT CASE WHEN name LIKE '%™%' THEN REPLACE(name, '™', '')
				WHEN name LIKE '% - %' THEN split_part(name, ' - ', 1)
				ELSE name END AS name
	FROM app_store_apps) AS app_store
	INNER JOIN (SELECT CASE WHEN name LIKE '%™%' THEN REPLACE(name, '™', '')
					WHEN name LIKE '% - %' THEN split_part(name, ' - ', 1)
					ELSE name END AS name
		FROM play_store_apps) AS play_store USING (name);

-- Getting top games from each store
SELECT name,
	rating,
	primary_genre,
	est_downloads,
	est_revenue - marketing_cost - app_cost AS ROI
FROM (SELECT *,
		ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
		review_count::numeric * 100 AS est_downloads,
		CASE WHEN price <= 2.5 THEN 25000
			ELSE (price * 10000)::integer END AS app_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
	FROM app_store_apps
	WHERE rating > 0) AS app_store
WHERE est_downloads > 10000 AND (est_revenue - marketing_cost - app_cost) > 0 AND primary_genre = 'Games'
ORDER BY ROI DESC;

SELECT DISTINCT name,
	rating,
	category AS genre,
	est_downloads,
	est_revenue - marketing_cost - app_cost AS ROI
FROM (SELECT *,
		ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
		REPLACE(REPLACE(install_count, '+', ''), ',', '')::numeric AS est_downloads,
		CASE WHEN price::money::numeric <= 2.5 THEN 25000
			ELSE (price::money::numeric * 10000)::integer END AS app_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
	FROM play_store_apps) AS play_store
WHERE est_downloads > 10000 AND (est_revenue - marketing_cost - app_cost) > 0 AND category = 'GAME'
ORDER BY ROI DESC;

-- Finding common apps
SELECT name
FROM (SELECT *,
		ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
		review_count::numeric * 100 AS est_downloads,
		CASE WHEN price <= 2.5 THEN 25000
			ELSE (price * 10000)::integer END AS app_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
	FROM app_store_apps
	WHERE rating > 0) AS app_store
WHERE est_downloads > 10000 AND (est_revenue - marketing_cost - app_cost) > 0 AND primary_genre = 'Games'
INTERSECT
SELECT DISTINCT name
FROM (SELECT *,
		CASE WHEN category = 'FAMILY'
			AND REGEXP_REPLACE(genres, ';.*','') IN( 'Casual', 'Casino', 'Arcade', 'Puzzle', 'Role Playing', 'Simulation', 'Sports', 'Adventure', 'Card', 'Strategy','Trivia', 'Racing', 'Action', 'Board', 'Word')	THEN 'GAME'
			ELSE category END AS category_new,
		ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
		REPLACE(REPLACE(install_count, '+', ''), ',', '')::numeric AS est_downloads,
		CASE WHEN price::money::numeric <= 2.5 THEN 25000
			ELSE (price::money::numeric * 10000)::integer END AS app_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
		(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
	FROM play_store_apps) AS play_store
WHERE est_downloads > 10000 AND (est_revenue - marketing_cost - app_cost) > 0 AND category_new = 'GAME';

-- Finding shared app list
SELECT DISTINCT app.name,
	ROUND((MAX(app.review_count::numeric) + MAX(play.review_count::numeric)) / 2, 0) AS avg_reviews,
	ROUND((MAX(app.rating) + AVG(play.rating)) / 2, 1) AS avg_rating
FROM app_store_apps AS APP
	INNER JOIN ( SELECT name
				FROM (SELECT *,
						ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
						review_count::numeric * 100 AS est_downloads,
						CASE WHEN price <= 2.5 THEN 25000
							ELSE (price * 10000)::integer END AS app_cost,
						(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
						(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
					FROM app_store_apps
					WHERE rating > 0) AS app_store
				WHERE primary_genre = 'Games'
				INTERSECT
				SELECT DISTINCT name
				FROM (SELECT *,
						CASE WHEN category = 'FAMILY'
							AND REGEXP_REPLACE(genres, ';.*','') IN( 'Casual', 'Casino', 'Arcade', 'Puzzle', 'Role Playing', 'Simulation', 'Sports', 'Adventure', 'Card', 'Strategy','Trivia', 'Racing', 'Action', 'Board', 'Word')	THEN 'GAME'
							ELSE category END AS category_new,
						ROUND((rating * 2) - 0.5, 0) + 1 AS proj_lifespan,
						REPLACE(REPLACE(install_count, '+', ''), ',', '')::numeric AS est_downloads,
						CASE WHEN price::money::numeric <= 2.5 THEN 25000
							ELSE (price::money::numeric * 10000)::integer END AS app_cost,
						(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 1000 AS marketing_cost,
						(ROUND((rating * 2) - 0.5, 0) + 1) * 12 * 5000 AS est_revenue
					FROM play_store_apps) AS play_store
				WHERE category_new = 'GAME'
			) AS app_list USING (name)
	INNER JOIN play_store_apps AS play USING (name)
GROUP BY app.name
HAVING ROUND((MAX(app.review_count::numeric) + MAX(play.review_count::numeric)) / 2, 0) > 100000 AND ROUND((MAX(app.rating) + AVG(play.rating)) / 2, 1) > 4.5
ORDER BY avg_reviews
LIMIT 10;


	

