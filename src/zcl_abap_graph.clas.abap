class zcl_abap_graph definition public final create private .

  public section.
    constants: c_browser_url type string value 'https://marcellourbani.github.io/Graphviz-browser/index.html#/graph'.
    data: default_node_attr  type ref to zcl_abap_graph_attr read-only,
          default_graph_attr type ref to zcl_abap_graph_attr read-only.

    class-methods create
      returning
        value(r_result) type ref to zcl_abap_graph.
    methods:
      generate_html_wrapper
        importing baseurl         type string default c_browser_url
                  value(comments) type string optional
        returning value(wrapper)  type string,

      generate returning value(r_result) type string,
      addnode importing node type ref to zif_abap_graph_node,
      has_id importing i_id            type string
             returning value(r_result) type abap_bool,
      register_id
        importing
          id type string.

  protected section.
  private section.
    data temp type string.
    data uploadpath type string.
    data downloadpath type string.
    data nodes type zif_abap_graph_node=>tt_node.
    data valid_ids type hashed table of string with unique key table_line.

    methods get_defaults
      returning
        value(r_result) type string.
endclass.



class zcl_abap_graph implementation.

  method create.

    create object r_result.
    r_result->default_node_attr = zcl_abap_graph_attr=>create( ).
    r_result->default_graph_attr = zcl_abap_graph_attr=>create( ).
    r_result->default_node_attr->set( name = 'shape' value = 'record' ).
    r_result->default_graph_attr->set( name = 'rankdir' value = 'LR' ).

  endmethod.

  method generate_html_wrapper.
    data: lines      type table of string,
          graphlines type table of string,
          graph      type string,
          iframe     type string.
    field-symbols: <graphline> like line of graphlines.
    graph = generate( ).
    replace all occurrences of '\' in graph with '\\'.
    replace all occurrences of '''' in graph with '\'''.

    split graph at cl_abap_char_utilities=>newline into table graphlines.

    concatenate  '<iframe src="' baseurl '?useparentsource=true">' into iframe.
    concatenate '<!-' comments '->' into comments.
    append:
  '<!DOCTYPE html>' to lines,
  '<html lang="en">' to lines,
  comments to lines,
  '' to lines,
  '<head>' to lines,
  '    <meta charset="utf-8">' to lines,
  '    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">' to lines,
  '    <title>Graph display</title>' to lines,
  '    <style>' to lines,
  '        iframe {' to lines,
  '            position: fixed;' to lines,
  '            top: 0px;' to lines,
  '            left: 0px;' to lines,
  '            bottom: 0px;' to lines,
  '            right: 0px;' to lines,
  '            width: 100%;' to lines,
  '            height: 100%;' to lines,
  '            border: none;' to lines,
  '            margin: 0;' to lines,
  '            padding: 0;' to lines,
  '            overflow: hidden;' to lines,
  '            z-index: 999999;' to lines,
  '        }' to lines,
  '    </style>' to lines,
  '    <script>' to lines,
  '        var graphsource =  ' to lines.
    loop at graphlines assigning <graphline>.

      concatenate '''' <graphline> '\n'' +' into graph.
      append graph to lines.

    endloop.

    append:
    '       '''' ;' to lines,
    '        function receiveMessage(event) {' to lines,
    '            if (event.data === "requestGraphSource") { ' to lines,
    '                event.source.postMessage("graphSource=" + graphsource, "*");' to lines,
    '            }' to lines,
    '        }' to lines,
    '        window.addEventListener("message", receiveMessage, false);' to lines,
    '    </script>' to lines,
    '</head>' to lines,
    '' to lines,
    '<body>' to lines,
    iframe to lines,
    '        Your browser doesn''t support iframes' to lines,
    '    </iframe>' to lines,
    '</body>' to lines,
    '' to lines,
    '</html>'  to lines.

    concatenate lines of lines into wrapper separated by  cl_abap_char_utilities=>cr_lf.
  endmethod.


  method generate.
    data: itemcode  type string,
          nodelinks type zif_abap_graph_node=>tt_link,
          nodescode type string,
          links     type zif_abap_graph_node=>tt_link.
    field-symbols: <node> like line of nodes,
                   <link> like line of links.
    agdefinitions.

    loop at nodes assigning <node>.
      itemcode  = <node>->render( ).
      nodelinks = <node>->getlinks( ).
      append lines of nodelinks to links.
      agexpand '{nodescode}\n{itemcode}' nodescode.
    endloop.

    loop at links assigning <link>.
      clear itemcode.
      if <link>-attributes is bound.
        itemcode  = <link>-attributes->render( ).
      endif.

      agexpand '{nodescode}\n{<link>-parentid} -> {<link>-childid}{itemcode};' nodescode.
    endloop.

    itemcode = get_defaults( ).

    agexpand 'digraph \{\n{itemcode}\n{nodescode}\n\}' r_result.

  endmethod.

  method addnode.
    register_id( node->id ).
    append node to nodes.
  endmethod.


  method get_defaults.
    data:graphdefaults type string.

    r_result = default_node_attr->render( ).
    if not r_result is initial.
      concatenate 'node' r_result into r_result.
    endif.

    graphdefaults = default_graph_attr->render( ).
    if graphdefaults <> ''.
      concatenate 'graph' graphdefaults space r_result into r_result respecting blanks.
    endif.
  endmethod.


  method has_id.
    read table valid_ids with table key table_line = i_id transporting no fields.
    if sy-subrc = 0.
      r_result = abap_true.
    endif.
  endmethod.


  method register_id.
    if id is initial.
      zcx_abap_graph=>raise( 'A node or node part must have a valid ID' ).
    endif.

    if has_id( id ) = abap_true.
      zcx_abap_graph=>raise( 'A node or node part must have an unique ID' ).
    endif.

    insert id into table valid_ids.
  endmethod.

endclass.
