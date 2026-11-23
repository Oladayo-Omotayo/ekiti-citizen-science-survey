-- =====================================================================
-- Cleaning the biodiversity survey for the jittered strip plot
-- (age group vs willingness, community shown as tooltip)
--
-- Written for SQLite (e.g. DB Browser for SQLite, free).
-- Assumes the Excel sheet has been imported as a table called survey_raw,
-- keeping the original column headers.
--
-- Output: a table called survey_clean with ONLY the columns the plot needs:
--   respondent_id | age_group | age_order | willingness | willing_flag | community
-- =====================================================================

DROP TABLE IF EXISTS survey_clean;

CREATE TABLE survey_clean AS
WITH

-- 1. Give every respondent an ID and tidy the three columns we need
base AS (
    SELECT
        ROW_NUMBER() OVER ()                                              AS respondent_id,
        TRIM("AGE")                                                       AS age_raw,
        LOWER(TRIM("WILLINGNESS TO JOIN CITIZEN SCIENCE PROJECT"))        AS willing_raw,
        LOWER(TRIM("COMMUNITY"))                                          AS community_raw
    FROM survey_raw
),

-- 2. Lookup table: how each community was typed -> how it should appear
community_map (community_raw, community_clean) AS (
    VALUES
        ('ado ekiti',                       'Ado Ekiti'),
        ('afao ekiti',                      'Afao Ekiti'),
        ('abuja',                           'Abuja'),
        ('adpi',                            'ADPI'),
        ('egbe ekiti',                      'Egbe Ekiti'),
        ('eksu',                            'EKSU'),
        ('fuoye',                           'FUOYE'),
        ('ifaki ekiti',                     'Ifaki Ekiti'),
        ('ijero ekiti',                     'Ijero Ekiti'),
        ('ijesa isu ekiti',                 'Ijesa Isu Ekiti'),
        ('ikere ekiti',                     'Ikere Ekiti'),
        ('ikogosi ekiti',                   'Ikogosi Ekiti'),
        ('ikole ekiti',                     'Ikole Ekiti'),
        ('ilokun',                          'Ilokun'),
        ('irasa ado ekiti',                 'Irasa Ado Ekiti'),
        ('ise ekiti',                       'Ise Ekiti'),
        ('iye ekiti',                       'Iye Ekiti'),
        ('iyin ekiti',                      'Iyin Ekiti'),
        ('ode ekiti',                       'Ode Ekiti'),
        ('olorunsogo zone 5, road 2',       'Olorunsogo Zone 5, Road 2'),
        ('orun ekiti',                      'Orun Ekiti'),
        ('otun ekiti',                      'Otun Ekiti'),
        ('oye ekiti',                       'Oye Ekiti'),
        ('river',                           'River'),
        ('uk government',                   'UK Government'),
        ('young africa leaders initiative', 'Young Africa Leaders Initiative'),
        ('nil',                             'Not stated'),
        ('',                                'Not stated')
)

-- 3. Standardise everything and keep only valid rows
SELECT
    b.respondent_id,

    CASE b.age_raw
        WHEN '21-40' THEN '21-40'
        WHEN '41-60' THEN '41-60'
        WHEN '>60'   THEN 'Over 60'
    END                                                AS age_group,

    CASE b.age_raw                                     -- x position on the plot
        WHEN '21-40' THEN 1
        WHEN '41-60' THEN 2
        WHEN '>60'   THEN 3
    END                                                AS age_order,

    CASE b.willing_raw
        WHEN 'yes' THEN 'Yes'
        WHEN 'no'  THEN 'No'
    END                                                AS willingness,

    CASE b.willing_raw                                 -- y position on the plot
        WHEN 'yes' THEN 1
        WHEN 'no'  THEN 0
    END                                                AS willing_flag,

    COALESCE(m.community_clean,
             TRIM(b.community_raw),
             'Not stated')                             AS community

FROM base b
LEFT JOIN community_map m
       ON m.community_raw = COALESCE(b.community_raw, '')

WHERE b.age_raw     IN ('21-40', '41-60', '>60')       -- drop rows with no valid age
  AND b.willing_raw IN ('yes', 'no')                   -- drop rows with no valid answer
ORDER BY b.respondent_id;


-- =====================================================================
-- CHECKS (run after creating the table)
-- =====================================================================

-- a) How many respondents survived cleaning? (expected: 57)
SELECT COUNT(*) AS respondents FROM survey_clean;

-- b) The numbers the plot labels should show
SELECT age_group,
       SUM(willing_flag)  AS said_yes,
       COUNT(*)           AS total
FROM survey_clean
GROUP BY age_order, age_group
ORDER BY age_order;

-- c) Any community that slipped through the lookup table unchanged?
--    (unmapped names stay all lower-case, so they show up here. Expected: none)
SELECT DISTINCT community
FROM survey_clean
WHERE community = LOWER(community);
