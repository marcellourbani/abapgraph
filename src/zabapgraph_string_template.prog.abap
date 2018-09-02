define agdefinitions.
  data: __abapgraph_templ type ref to zcl_abap_graph_string_template.

  field-symbols: <__abapgraph_varname>  type string,
                 <__abapgraph_varvalue> type any.
end-of-definition.

define agexpand.
  __abapgraph_templ = zcl_abap_graph_string_template=>create( &1 ).
  loop at __abapgraph_templ->varnames assigning <__abapgraph_varname>.
    assign (<__abapgraph_varname>) to <__abapgraph_varvalue>.
    if sy-subrc = 0.
      __abapgraph_templ->set_variable( name = <__abapgraph_varname> value = <__abapgraph_varvalue> ).
    endif.
  endloop.
  &2 = __abapgraph_templ->render( ).

end-of-definition.
