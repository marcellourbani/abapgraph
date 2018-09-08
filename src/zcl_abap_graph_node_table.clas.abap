class zcl_abap_graph_node_table definition public final create private .

  public section.

    interfaces zif_abap_graph_node .

    aliases attributes for zif_abap_graph_node~attributes .
    aliases graph      for zif_abap_graph_node~graph .
    aliases id         for zif_abap_graph_node~id .
    aliases getlinks   for zif_abap_graph_node~getlinks .
    aliases linkto     for zif_abap_graph_node~linkto .
    aliases render     for zif_abap_graph_node~render .
    aliases tt_link    for zif_abap_graph_node~tt_link .
    aliases tt_node    for zif_abap_graph_node~tt_node .
    aliases ty_link    for zif_abap_graph_node~ty_link .
    aliases ty_nod     for zif_abap_graph_node~ty_node .

    types:
      begin of ty_column,
        id   type string,
        name type string,
      end of ty_column,
      begin of ty_cell,
        columnid   type string,
        value      type string,
        partid     type string,
        attributes type ref to zcl_abap_graph_attr,
      end of ty_cell,
      ty_line type hashed table of ty_cell with unique key columnid.

    data: headerattr like attributes,
          titleattr  like attributes.

    class-methods create
      importing
        id              type string
        label           type string optional
        graph           type ref to zcl_abap_graph
        escape          type abap_bool default abap_true
      returning
        value(r_result) type ref to zcl_abap_graph_node_table .
    methods:
      setcolumn importing id type string name type string optional,
      setcell   importing
                  columnid           type string
                  row                type i
                  value              type string
                  escape             type abap_bool default abap_true
                  value(partid)      type string optional
                  attributes         type ref to zcl_abap_graph_attr optional
                returning
                  value(componentid) type string .
  protected section.
    data: mainlabel type string.
  private section.
    data: links   type tt_link,
          columns type standard table of ty_column with key id,
          cells   type standard table of ty_line.

    methods validatesource
      importing
        i_source type string.
    methods getcomp
      importing
        partid          type string
      returning
        value(r_result) type string.
    methods check_column
      importing
        i_columnid type string.
    methods hasheaders
      returning
        value(r_result) type abap_bool.
    methods get_cell
      importing
        line            type zcl_abap_graph_node_table=>ty_line
        columnid        type string
      returning
        value(r_result) type string.

endclass.



class zcl_abap_graph_node_table implementation.


  method check_column.

    read table columns with key id = i_columnid transporting no fields.
    if sy-subrc <> 0.
      zcx_abap_graph=>raise( 'A node or node part must have a valid ID' ).
    endif.

  endmethod.


  method create.

    if not graph is bound.
      zcx_abap_graph=>raise( 'A node requires valid parent graph' ).
    endif.
    create object r_result.
    r_result->id = zcl_abap_graph_utilities=>quoteifneeded( id ).
    r_result->graph = graph.
    r_result->attributes = zcl_abap_graph_attr=>create( ).
    if escape = abap_true.
      r_result->mainlabel  = cl_http_utility=>escape_html( label ).
    else.
      r_result->mainlabel  = label .
    endif.
    r_result->attributes->set( name  = 'shape' value = 'plaintext' ).
    r_result->headerattr = zcl_abap_graph_attr=>create( abap_true ).
    r_result->titleattr = zcl_abap_graph_attr=>create( abap_true ).
    graph->addnode( r_result ).

  endmethod.


  method getcomp.
    if partid <> ''.
      concatenate ' port=' partid ' ' into r_result respecting blanks.
    endif.
  endmethod.


  method get_cell.
    data: attrtext type string,
          porttext type string.
    field-symbols: <cell> like line of line.
    agdefinitions.

    read table line with table key columnid = columnid assigning <cell>.
    if sy-subrc = 0.
      porttext = getcomp(  <cell>-partid ).
      if <cell>-attributes is bound.
        attrtext = <cell>-attributes->render(  ).
        agexpand '<td {attrtext}{porttext}>{<cell>-value}</td>' r_result.
      else.
        agexpand '<td{porttext}>{<cell>-value}</td>' r_result.
      endif.
    else.
      r_result = '<td></td>'.
    endif.
  endmethod.


  method hasheaders.
    loop at columns transporting no fields where name <> ''.
      r_result = abap_true.
      exit.
    endloop.
  endmethod.


  method setcell.
    data: numlines type i,
          missing  type i,
          cell     type ty_cell.

    field-symbols: <line> like line of cells.

    check_column( columnid ).
    if partid <> ''.
      partid = zcl_abap_graph_utilities=>quoteifneeded( partid ).
      concatenate id ':' partid into componentid.
      "will raise an exception for invalid/already used IDs
      graph->register_id( componentid ).
    endif.
    read table cells index row assigning <line>.
    if sy-subrc <> 0.
      numlines = lines( cells ).
      missing  = row - numlines.
      do missing times.
        append initial line to cells assigning <line>.
      enddo.
    endif.

    delete table <line> with table key columnid = columnid.
    cell-columnid   = columnid.
    cell-partid     = partid.
    if escape = abap_true.
      cell-value      = cl_http_utility=>escape_html( value ).
    else.
      cell-value      = value .
    endif.
    cell-attributes = attributes.
    insert cell into table <line>.

  endmethod.


  method setcolumn.
    field-symbols: <column> like line of columns.

    delete columns where id = id.
    append initial line to columns assigning <column>.

    <column>-id = id.
    <column>-name = name.
  endmethod.


  method validatesource.
    data: parent type string,
          child  type string.
    if graph->has_id( i_source ) = abap_true.
      find regex '(".+"):(".+")$' in i_source submatches parent child.
    endif.
    if sy-subrc <> 0 or parent <> id.
      zcx_abap_graph=>raise( 'Source must be a valid part of the node' ).
    endif.
  endmethod.


  method zif_abap_graph_node~getlinks.
    links = me->links.
  endmethod.


  method zif_abap_graph_node~linkto.
    data: partid type string,
          mainid type string.
    field-symbols: <link> like line of links.

    append initial line to links assigning <link>.
    if source = ''.
      <link>-parentid = id.
    else.
      validatesource( source ).
      <link>-parentid = source.
    endif.
    if graph->has_id( destination ) = abap_false.
      zcx_abap_graph=>raise( 'Destination must be a valid part of the node' ).
    endif.
    <link>-childid    = destination.
    <link>-attributes = zcl_abap_graph_attr=>create( ).
    <link>-attributes->set( name  = 'label' value = label ).
    <link>-attributes->set( name  = 'color' value = color ).
    <link>-attributes->set( name  = 'fontcolor' value = color ).
  endmethod.


  method zif_abap_graph_node~render.
    data: temp       type string,
          comp       type string,
          numcols    type string,
          item       type string,
          cellcode   type string,
          attrs      type string.
    field-symbols: <column> like line of columns,
                   <line>   like line of cells.

*    field-symbols: <comp> like line of components.
    agdefinitions.

    numcols = lines( columns ).
    agexpand '<<table border="0" cellborder="1" cellspacing="0">' dotsource.
    "table title/name
    if mainlabel <> ''.
      headerattr->set( name = 'colspan' value = numcols ).
      attrs = headerattr->render( ).
      agexpand '{dotsource}<tr><td{attrs}>{mainlabel}</td></tr>' dotsource.
    endif.

    "column headers
    if hasheaders( ) = abap_true.
      temp = ''.
      attrs = titleattr->render( ).
      loop at columns assigning <column>.
        item = <column>-name.
        if <column>-name is initial.
          item = <column>-id.
        endif.
        agexpand '{temp}<td{attrs}>{item}</td>' temp.
      endloop.
      agexpand '{dotsource}\n<tr>{temp}</tr>' dotsource.
    endif.

    "table contents
    loop at cells assigning <line>.
      temp = ''.
      loop at columns assigning <column>.
        item = get_cell( line = <line> columnid = <column>-id ).
        concatenate temp item into temp respecting blanks.
      endloop.
      agexpand '{dotsource}\n<tr>{temp}</tr>' dotsource.
    endloop.

    agexpand '{dotsource}\n</table>>' dotsource.

    attributes->setraw( name  = 'label' value = dotsource ).
    temp = attributes->render( ).

    agexpand '{id}{temp};' dotsource.

  endmethod.
endclass.
