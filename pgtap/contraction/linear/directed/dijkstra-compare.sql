
BEGIN;

SELECT plan(334);

UPDATE edge_table SET cost = sign(cost) + 0.001 * id * id, reverse_cost = sign(reverse_cost) + 0.001 * id * id;
ALTER SEQUENCE edge_table_id_seq RESTART WITH 19;

--step 1: Initial tables

SELECT isnt_empty($$SELECT id, source, target, cost, reverse_cost FROM edge_table$$);
SELECT isnt_empty($$SELECT id FROM edge_table_vertices_pgr$$);


-- add extra columns to the edges and vertices table
ALTER TABLE edge_table
ADD is_contracted BOOLEAN DEFAULT false,
ADD contracted_vertices integer[];

ALTER TABLE edge_table_vertices_pgr
ADD is_contracted BOOLEAN DEFAULT false,
ADD contracted_vertices integer[];

SELECT has_column('edge_table', 'is_contracted');
SELECT has_column('edge_table_vertices_pgr', 'is_contracted');
SELECT has_column('edge_table', 'contracted_vertices');
SELECT has_column('edge_table_vertices_pgr', 'contracted_vertices');

SELECT * INTO contraction_info FROM pgr_contraction(
    'SELECT id, source, target, cost, reverse_cost FROM edge_table',
    ARRAY[2]::integer[], 1, ARRAY[]::BIGINT[], true);

PREPARE c_info AS
SELECT type, id, contracted_vertices, source, target, cost
FROM (VALUES
    ('e', -1, ARRAY[8], 5, 7, '2.085'),
    ('e', -2, ARRAY[8], 7, 5, '2.085')
) AS t(type, id, contracted_vertices, source, target, cost );

SELECT set_eq(
    $$SELECT type, id, contracted_vertices, source, target, cost::TEXT FROM contraction_info$$,
    'c_info',
    'Contraction results');

-- add the new edges
INSERT INTO edge_table(source, target, cost, reverse_cost, contracted_vertices, is_contracted)
SELECT source, target, cost, -1, contracted_vertices, true
FROM contraction_info
WHERE type = 'e';

-- Indicate vertices that were contracted
UPDATE edge_table_vertices_pgr
SET is_contracted = true
WHERE id IN (SELECT  unnest(contracted_vertices) FROM  contraction_info);

-- add the contracted vertices on the vertices table
UPDATE edge_table_vertices_pgr
SET contracted_vertices = contraction_info.contracted_vertices
FROM contraction_info
WHERE type = 'v' AND edge_table_vertices_pgr.id = contraction_info.id;

SELECT id
    FROM edge_table
    WHERE is_contracted;

SELECT set_eq($$SELECT id
    FROM edge_table
    WHERE NOT is_contracted$$,
    $$SELECT unnest(ARRAY[1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18])$$
);

SELECT set_eq($$SELECT id
    FROM edge_table
    WHERE is_contracted$$,
    $$SELECT unnest(ARRAY[19, 20])$$,
    'Edges id added to edge table'
);

-- the contracted graph
PREPARE c_graph AS
SELECT source, target, cost::TEXT, reverse_cost::TEXT FROM edge_table
WHERE
    EXISTS (SELECT id FROM edge_table_vertices_pgr AS v WHERE NOT is_contracted AND v.id = edge_table.source)
    AND
    EXISTS (SELECT id FROM edge_table_vertices_pgr AS v WHERE NOT is_contracted AND v.id = edge_table.target);

PREPARE c_expected_graph AS
SELECT source, target, cost, reverse_cost
FROM (VALUES
    ( 1,    2,   '1.001',   '1.001'),
    ( 2,    3,  '-0.996',   '1.004'),
    ( 3,    4,   '-0.991',  '1.009'),
    ( 2,    5,   '1.016',   '1.016'),
    ( 3,    6,   '1.025',   '-0.975'),
    ( 5,    6,   '1.064',   '1.064'),
    ( 6,    9,   '1.081',   '1.081'),
    ( 5,   10,   '1.1',     '1.1'),
    ( 6,   11,   '1.121',   '-0.879'),
    (10,   11,   '1.144',   '-0.856'),
    (11,   12,   '1.169',   '-0.831'),
    (10,   13,   '1.196',   '1.196'),
    ( 9,   12,   '1.225',   '1.225'),
    ( 4,    9,   '1.256',   '1.256'),
    (14,   15,   '1.289',   '1.289'),
    (16,   17,   '1.324',   '1.324'),
    ( 7,    5,   '2.085',   '-1'),
    ( 5,    7,   '2.085',   '-1'))
AS t(source, target, cost, reverse_cost);

SELECT set_eq('c_graph', 'c_expected_graph', 'The contracted graph');

CREATE OR REPLACE FUNCTION compare_dijkstra(
    BIGINT, BIGINT)
RETURNS SETOF TEXT AS
$BODY$
DECLARE
    graph_q TEXT;
BEGIN
    graph_q := format($query$
            WITH
            contracted_section AS (
                SELECT unnest(contracted_vertices) AS id
                FROM edge_table_vertices_pgr
                WHERE ARRAY[%1$s, %2$s] && contracted_vertices
                UNION
                SELECT unnest(contracted_vertices) AS id
                FROM edge_table
                WHERE ARRAY[%1$s, %2$s] && contracted_vertices
            ),
            vertices AS (
                SELECT id FROM edge_table_vertices_pgr
                WHERE NOT is_contracted OR id IN (SELECT id FROM contracted_section)
            )
            SELECT id, source, target, cost, reverse_cost FROM edge_table
            WHERE
            EXISTS (SELECT id FROM vertices WHERE vertices.id = edge_table.source)
            AND
            EXISTS (SELECT id FROM vertices WHERE vertices.id = edge_table.target)
            $query$, $1::BIGINT, $2::BIGINT);
    -- set client_min_messages TO notice;
    -- raise notice '%', graph_q;
    CREATE TEMP TABLE nodes_on_graph AS
    WITH dijkstra_r AS (
        SELECT edge, node FROM pgr_dijkstra(graph_q, $1::BIGINT, $2::BIGINT, true))
    SELECT node FROM dijkstra_r
    UNION
    SELECT unnest(contracted_vertices)
    FROM dijkstra_r JOIN edge_table ON (edge = id) WHERE is_contracted = true;

    CREATE TEMP TABLE dijkstra_contracted AS
    SELECT * FROM pgr_dijkstra($$SELECT id, source, target, cost, reverse_cost
        FROM edge_table
        WHERE
            contracted_vertices IS NULL
            AND source IN (SELECT * FROM nodes_on_graph)
            AND target IN (SELECT * FROM nodes_on_graph)$$, $1::BIGINT, $2::BIGINT, true);

    CREATE TEMP TABLE dijkstra_normal AS
    SELECT * FROM pgr_dijkstra($$SELECT id, source, target, cost, reverse_cost
        FROM edge_table WHERE id < 19$$, $1::BIGINT, $2::BIGINT, true);
    RETURN QUERY
    SELECT set_eq(
        $$SELECT * FROM dijkstra_contracted$$,
        $$SELECT * FROM dijkstra_normal$$,
        'From ' || $1 || ' to ' || $2 );

    DROP TABLE dijkstra_contracted;
    DROP TABLE dijkstra_normal;
    DROP TABLE nodes_on_graph;
END
$BODY$
LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION compare_dijkstra_all()
RETURNS SETOF TEXT AS
$BODY$
DECLARE
    i INTEGER;
    j INTEGER;

BEGIN
    FOR i IN 1..18 LOOP
        FOR j IN 1..18 LOOP
            RETURN QUERY
            SELECT compare_dijkstra(i, j);
        END LOOP;
    END LOOP;
END
$BODY$
LANGUAGE plpgsql;

SELECT compare_dijkstra_all();


SELECT finish();
