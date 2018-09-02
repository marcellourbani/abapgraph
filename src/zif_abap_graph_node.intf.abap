interface zif_abap_graph_node public.
  types: begin of ty_link,
           parentid   type string,
           childid    type string,
           attributes type ref to zcl_abap_graph_attr,
         end of   ty_link,
         tt_link type table of ty_link with key parentid childid,
         ty_node type ref to zif_abap_graph_node,
         tt_node type table of ty_node with default key.
  data: id         type string read-only,
        graph      type ref to zcl_abap_graph read-only,
        attributes type ref to zcl_abap_graph_attr read-only.

  methods: render returning value(dotsource) type string,
    linkto      importing destination type string
                          color       type string optional
                          label       type string optional
                          source      type string optional
                returning value(link) type ty_link,
    getlinks returning value(links) type tt_link.

endinterface.
