{{
    config(materialized='incremental')
}}

WITH nyt_reviews AS (
    SELECT * FROM {{ ref('nyt_reviews_cleansed') }}
),
unique_reviews AS (
    SELECT
        review_headline,
        review_date
    FROM
        nyt_reviews
    GROUP BY
        review_headline,
        review_date
    HAVING
        COUNT(*) = 1
)

SELECT
    {{ dbt_utils.surrogate_key(['author_name', 'movie_title', 'review_date']) }} AS id,
    review_headline AS headline,
    review_url AS url,
    summary_short AS summary,
    is_critics_pick
FROM (
    SELECT
        x.review_headline AS review_headline,
        review_url,
        summary_short,
        x.review_date AS review_date,
        is_critics_pick,
        -- additional cols for surrogate_key
        author_name,
        movie_title
    FROM 
        unique_reviews x
        JOIN nyt_reviews y
        ON x.review_headline = y.review_headline AND x.review_date = y.review_date
)
{% if is_incremental() %}
WHERE
    id NOT IN (SELECT id FROM {{ this }})
{% endif %}