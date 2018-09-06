*
report zabapgraph_demo.

data: graph type ref to zcl_abap_graph,
      ex    type ref to cx_root.

selection-screen begin of screen 1001.
* dummy for triggering screen on Java SAP GUI
selection-screen end of screen 1001.
selection-screen comment /1(50) text-001.
parameters: p_screen radiobutton group dest,
            p_file   radiobutton group dest.


start-of-selection.
  try.
      perform main.

    catch cx_root into ex.
      message ex type 'I'.
  endtry.

class dummy definition.
  public section.
    class-data: _instance type ref to dummy.
    data: tr type e070.
endclass.

*
form main.
  data: gv_html_viewer type ref to cl_gui_html_viewer,
        node1          type ref to zcl_abap_graph_node_simple,
        node2          type ref to zcl_abap_graph_node_simple,
        node3          type ref to zcl_abap_graph_node_record,
        node4          type ref to zcl_abap_graph_node_table,
        partid1        type string,
        partid2        type string,
        cellattrs      type ref to zcl_abap_graph_attr,
        partid3        type string.

  try.
      graph = zcl_abap_graph=>create( ).
      node1  = zcl_abap_graph_node_simple=>create( id = '1' label = 'node 1' graph = graph ).
      node3 = zcl_abap_graph_node_record=>create( id = '3' label = 'record'  graph = graph ).
      node3->addcomponent( name = 'First' value = 'foo' ).
      node3->addcomponent( name = 'Second' value = 'bar'  ).
      partid1 = node3->addcomponent( name = 'protected' value = 'protectedv' partid = 'p3'
        visibility = zcl_abap_graph_node_record=>visprotected  ).
      partid2 = node3->addcomponent( name = 'private' value = 'privatev' partid = 'p4'
        visibility = zcl_abap_graph_node_record=>visprivate ).
      node2  = zcl_abap_graph_node_simple=>create( id = '2' label = 'node 2' graph = graph ).


      node4 = zcl_abap_graph_node_table=>create( graph = graph id = '"{table1}"' label = 'Table 1' ).
      node4->setcolumn( id = 'COL1' name = 'First column' ).
      node4->setcolumn( id = 'COL2' name = 'Second <s>column</s>' ).
      node4->setcolumn( id = 'COL3' ).
      node4->setcell( columnid = 'COL1' row = 3 value = '3,1' ).
      node4->setcell( columnid = 'COL3' row = 1 value = '1,3' ).
      cellattrs = zcl_abap_graph_attr=>create( ).
      cellattrs->set( name = 'bgcolor' value = 'red' ).
      partid3 = node4->setcell( columnid = 'COL2' row = 2 value = '2,2' attributes = cellattrs partid = 'central' ).

      node1->linkto( destination = node2->id label = 'link' ).
      node1->linkto( node3->id ).
      node3->linkto( source = partid1 destination = partid2 color = 'red' label = 'link between record members'  ).
      node2->linkto( partid2 ).
      node1->linkto( node4->id ).
      node3->linkto( destination = partid3
          color       = 'green'
          label       = 'to table center'
          source      = partid2 ).


      if p_screen is initial.
        zcl_abap_graph_utilities=>show_in_browser( graph ).
      else.

        create object gv_html_viewer
          exporting
            query_table_disabled = abap_true
            parent               = cl_gui_container=>screen0.

        zcl_abap_graph_utilities=>show_in_viewer( viewer = gv_html_viewer graph = graph ).

        call selection-screen 1001. " trigger screen
      endif.
    catch cx_root into ex.
      message ex type 'I'.
  endtry.

endform.
