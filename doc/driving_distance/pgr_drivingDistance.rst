..
   ****************************************************************************
    pgRouting Manual
    Copyright(c) pgRouting Contributors

    This documentation is licensed under a Creative Commons Attribution-Share
    Alike 3.0 License: https://creativecommons.org/licenses/by-sa/3.0/
   ****************************************************************************

|

* **Supported versions:**
  `Latest <https://docs.pgrouting.org/latest/en/pgr_drivingDistance.html>`__
  (`3.3 <https://docs.pgrouting.org/3.3/en/pgr_drivingDistance.html>`__)
  `3.2 <https://docs.pgrouting.org/3.2/en/pgr_drivingDistance.html>`__
  `3.1 <https://docs.pgrouting.org/3.1/en/pgr_drivingDistance.html>`__)
  `3.0 <https://docs.pgrouting.org/3.0/en/pgr_drivingDistance.html>`__
* **Unsupported versions:**
  `2.6 <https://docs.pgrouting.org/2.6/en/pgr_drivingDistance.html>`__
  `2.5 <https://docs.pgrouting.org/2.5/en/pgr_drivingDistance.html>`__
  `2.4 <https://docs.pgrouting.org/2.4/en/pgr_drivingDistance.html>`__
  `2.3 <https://docs.pgrouting.org/2.3/en/src/driving_distance/doc/pgr_drivingDistance.html>`__
  `2.2 <https://docs.pgrouting.org/2.2/en/src/driving_distance/doc/pgr_drivingDistance.html>`__
  `2.1 <https://docs.pgrouting.org/2.1/en/src/driving_distance/doc/dd_driving_distance_v3.html>`__
  `2.0 <https://docs.pgrouting.org/2.0/en/src/driving_distance/doc/dd_driving_distance.html>`__

``pgr_drivingDistance``
===============================================================================

``pgr_drivingDistance`` - Returns the driving distance from a start node.

.. figure:: images/boost-inside.jpeg
   :target: https://www.boost.org/libs/graph/doc/table_of_contents.html

   Boost Graph Inside

.. rubric:: Availability

* Version 2.1.0:

  * Signature change pgr_drivingDistance(single vertex)
  * New **Official** pgr_drivingDistance(multiple vertices)

* Version 2.0.0:

  * **Official** pgr_drivingDistance(single vertex)


Description
-------------------------------------------------------------------------------

Using the Dijkstra algorithm, extracts all the nodes that have costs less than
or equal to the value ``distance``.
The edges extracted will conform to the corresponding spanning tree.

Signatures
-------------------------------------------------------------------------------

.. parsed-literal::

    pgr_drivingDistance(`Edges SQL`_, **Root vid**,  **distance**
               [, directed])
    pgr_drivingDistance(`Edges SQL`_, **Root vids**, **distance**
               [, directed] [, equicost])
    RETURNS SET OF (seq, [from_v,] node, edge, cost, agg_cost)

.. index::
   single: drivingDistance(Single vertex)

Single Vertex
...............................................................................

.. parsed-literal::

    pgr_drivingDistance(`Edges SQL`_, **Root vid**,  **distance**
               [, directed])
    RETURNS SET OF (seq, node, edge, cost, agg_cost)

:Example: From vertex :math:`11` for a distance of :math:`3.0`

.. literalinclude:: doc-pgr_drivingDistance.queries
   :start-after: --q5
   :end-before: --q6

.. index::
   single: drivingDistance(Multiple vertices)

Multiple Vertices
...............................................................................

.. parsed-literal::

    pgr_drivingDistance(`Edges SQL`_, **Root vids**, **distance**
               [, directed] [, equicost])
    RETURNS SET OF (seq, from_v, node, edge, cost, agg_cost)

:Example: From vertices :math:`\{11, 16\}` for a distance of :math:`3.0` with
          equi-cost on a directed graph

.. literalinclude:: doc-pgr_drivingDistance.queries
   :start-after: --q6
   :end-before: --q10

Parameters
-------------------------------------------------------------------------------

.. include:: drivingDistance-category.rst
    :start-after: mst-dd-params_start
    :end-before: mst-dd-params_end

Optional parameters
...............................................................................

.. include:: dijkstra-family.rst
    :start-after: dijkstra_optionals_start
    :end-before: dijkstra_optionals_end

Driving distance optional parameters
...............................................................................

.. equicost_start

.. list-table::
   :width: 81
   :widths: 12, 8, 8, 60
   :header-rows: 1

   * - Column
     - Type
     - Default
     - Description
   * - ``equicost``
     - ``BOOLEAN``
     - ``true``
     - * When ``true`` the node will only appear in the closest ``from_v``
         list.
       * When ``false`` which resembles several calls using the single starting
         point signatures. Tie brakes are arbitrary.

.. equicost_end

Inner Queries
-------------------------------------------------------------------------------

Edges SQL
..............................................................................

.. include:: pgRouting-concepts.rst
   :start-after: basic_edges_sql_start
   :end-before: basic_edges_sql_end

Result Columns
-------------------------------------------------------------------------------

Returns SET OF ``(seq, from_v, node, edge, cost, agg_cost)``

.. list-table::
   :width: 81
   :widths: auto
   :header-rows: 1

   * - Parameter
     - Type
     - Description
   * - ``seq``
     - ``BIGINT``
     - Sequential value starting from :math:`1`.
   * - ``[from_v]``
     - ``BIGINT``
     - Identifier of the root vertex.

   * - ``node``
     - ``BIGINT``
     - Identifier of ``node`` within the limits from ``from_v``.
   * - ``edge``
     - ``BIGINT``
     - Identifier of the ``edge`` used to arrive to ``node``.

       - :math:`0` when ``node`` = ``from_v``.

   * - ``cost``
     - ``FLOAT``
     - Cost to traverse ``edge``.
   * - ``agg_cost``
     - ``FLOAT``
     - Aggregate cost from ``from_v`` to ``node``.

Where:

:ANY-INTEGER: SMALLINT, INTEGER, BIGINT
:ANY-NUMERIC: SMALLINT, INTEGER, BIGINT, REAL, FLOAT, NUMERIC

Additional Examples
-------------------------------------------------------------------------------

:Example: From vertices :math:`\{11, 16\}` for a distance of :math:`3.0` on an
          undirected graph

.. literalinclude:: doc-pgr_drivingDistance.queries
   :start-after: --q10
   :end-before: --q15

See Also
-------------------------------------------------------------------------------

* :doc:`pgr_alphaShape` - Alpha shape computation
* :doc:`sampledata` network.

.. rubric:: Indices and tables

* :ref:`genindex`
* :ref:`search`

