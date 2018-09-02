class zcl_abap_graph_attr definition public final create private .
  public section.
    types: begin of ty_attribute,
             name  type string,
             value type string,
           end of ty_attribute,
           tt_attribute type hashed table of ty_attribute with unique key name.
    "a full list of available attributes is at https://graphviz.gitlab.io/_pages/doc/info/attrs.html
    constants: atype_label        type string value 'label',
               atype_shape        type string value 'shape',
               atype_rankdir      type string value 'rankdir',
               atype_color        type string value 'color',
               rankdir_horizontal type string value 'LR',
               rankdir_vertical   type string value 'TB'.

    class-methods create
      returning
        value(r_result) type ref to zcl_abap_graph_attr.
    methods: set importing name type string value(value) type string,
             setraw importing name type string value type string,
      render importing forhtml           type abap_bool optional
             returning value(attrstring) type string.
  private section.
    data attributes type tt_attribute.
endclass.



class zcl_abap_graph_attr implementation.

  method create.

    create object r_result.

  endmethod.

  method set.
      value = zcl_abap_graph_utilities=>quoteifneeded( value ).
      setraw( name = name value = value ).
  endmethod.

  method render.
    field-symbols: <attr> like line of attributes.

    agdefinitions.

    loop at attributes assigning <attr>.
      agexpand '{attrstring} {<attr>-name} = {<attr>-value}' attrstring.
    endloop.

    if attrstring <> '' and forhtml = abap_false.
      agexpand '[{attrstring}]' attrstring.
    endif.

  endmethod.

  method setraw.

    data: attr type ty_attribute.
    delete table attributes with table key name = name.

    if value <> ''.
      attr-name = name.
      attr-value =  value .
      insert attr into table attributes.
    endif.

  endmethod.

endclass.
