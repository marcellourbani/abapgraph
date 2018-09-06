class zcl_abap_graph_node_simple definition public final create private .

  public section.
    interfaces: zif_abap_graph_node.
    aliases: attributes  for zif_abap_graph_node~attributes,
             id          for zif_abap_graph_node~id,
             graph       for zif_abap_graph_node~graph,
             ty_link     for zif_abap_graph_node~ty_link,
             tt_link     for zif_abap_graph_node~tt_link,
             getlinks    for zif_abap_graph_node~getlinks ,
             linkto      for zif_abap_graph_node~linkto ,
             render      for zif_abap_graph_node~render ,
             tt_node     for zif_abap_graph_node~tt_node ,
             ty_nod      for zif_abap_graph_node~ty_node .
    class-methods create importing id              type string
                                   graph           type ref to zcl_abap_graph
                                   value(label)    type string optional
                                   value(shape)    type string optional
                         returning value(r_result) type ref to zcl_abap_graph_node_simple.
  protected section.
  private section.
    data links type tt_link.

endclass.



class zcl_abap_graph_node_simple implementation.


  method create.
    if not graph is bound.
      zcx_abap_graph=>raise( 'A node requires valid parent graph' ).
    endif.

    create object r_result.
    r_result->id = zcl_abap_graph_utilities=>quoteifneeded( id ).
    r_result->attributes = zcl_abap_graph_attr=>create( ).
    label = cl_http_utility=>escape_html( label ).
    label = zcl_abap_graph_utilities=>quoteifneeded( label ).
    shape = zcl_abap_graph_utilities=>quoteifneeded( shape ).
    r_result->attributes->set( name  = 'label' value = label ).
    r_result->attributes->set( name  = 'shape' value = shape ).
    graph->addnode( r_result ).

  endmethod.

  method zif_abap_graph_node~getlinks.
    links = me->links.
  endmethod.

  method zif_abap_graph_node~linkto.
    field-symbols: <link> like line of links.

    append initial line to links assigning <link>.
    <link>-parentid = id."ignore source for simple nodes
    <link>-childid = destination.
    <link>-attributes = zcl_abap_graph_attr=>create( ).
    <link>-attributes->set( name  = 'label' value = label ).
    <link>-attributes->set( name  = 'color' value = color ).
    <link>-attributes->set( name  = 'fontcolor' value = color ).
  endmethod.


  method zif_abap_graph_node~render.
    data: attstr type string.

    attstr = attributes->render( ).
    concatenate id attstr ';' into dotsource.

  endmethod.
endclass.
