class zcl_abap_graph_string_template definition public create public .

  public section.

    data template type string read-only .
    data:
      varnames      type table of string read-only .
    data varvalues type tihttpnvp read-only .
    data var_not_found type flag read-only .

    class-methods create
      importing
        !i_template     type csequence
      returning
        value(r_result) type ref to zcl_abap_graph_string_template .
    methods set_variable
      importing
        !name  type string
        !value type any .
    methods render
      returning
        value(output) type string .
  protected section.
  private section.

    types:
      begin of ty_chunk,
        offset       type i,
        length       type i,
        replace      type flag,
        variablename type string,
        value        type string,
      end of ty_chunk .

    data:
      chunks type table of ty_chunk .

    methods parse .
    methods decode
      importing
        !encoded       type string
      returning
        value(decoded) type string .
    methods varname
      importing
        !match         type string
      returning
        value(varname) type string .
    methods get_var_value
      importing
        !i_variablename type string
      returning
        value(r_result) type string .
ENDCLASS.



CLASS ZCL_ABAP_GRAPH_STRING_TEMPLATE IMPLEMENTATION.


  method create.


    create object r_result.

    r_result->template = i_template.
    r_result->parse( ).


  endmethod.


  method decode.

    case encoded.
      when '\T'.
        decoded = cl_abap_char_utilities=>horizontal_tab.
      when '\N'.
        decoded = cl_abap_char_utilities=>newline.
      when '\R'.
        decoded = cl_abap_char_utilities=>cr_lf(1).
      when '\F'.
        decoded = cl_abap_char_utilities=>form_feed.
      when others.
        decoded = encoded+1.
    endcase.


  endmethod.


  method get_var_value.

    field-symbols: <var> like line of varvalues.
    read table varvalues assigning <var> with key name = i_variablename.
    if sy-subrc = 0.
      r_result = <var>-value.
    else.
      var_not_found = 'X'.
    endif.

  endmethod.


  method parse.

    data: regex     type ref to cl_abap_regex,
          matcher   type ref to cl_abap_matcher,
          matches   type match_result_tab,
          lastchunk like line of chunks,
          tmp       type string.
    field-symbols: <match> like line of matches,
                   <chunk> like line of chunks.

    create object regex
      exporting
        pattern     =
                      '(\\.)|(\{\s*(?:(?:[a-zA-Z_][a-z_0-9]*)|(?:<[a-zA-Z_][a-z_0-9]*>))(?:(?:->?|=>)[a-zA-Z_][a-z_0-9]*)*\s*\})'
        ignore_case = abap_false.

    matcher = regex->create_matcher( text = template ).
    matches = matcher->find_all( ).
    sort matches by offset.

    loop at matches assigning <match>.
      append initial line to chunks assigning <chunk>.
      "if there's something between matches, add it
      lastchunk-offset = lastchunk-offset + lastchunk-length.
      if lastchunk-offset < <match>-offset.
        <chunk>-length = <match>-offset - lastchunk-offset.
        <chunk>-offset = lastchunk-offset.
        append initial line to chunks assigning <chunk>.
      endif.
      "now the actual variable to be replaced
      <chunk>-length = <match>-length.
      <chunk>-offset = <match>-offset.
      <chunk>-replace = 'X'.
      tmp = template+<chunk>-offset(<chunk>-length).
      translate tmp to upper case.
      if tmp(1) = '\'.
        <chunk>-value = decode( tmp ).
      else.
        <chunk>-variablename = varname( tmp ).
      endif.
      lastchunk = <chunk>.

    endloop.
    lastchunk-offset = lastchunk-offset + lastchunk-length.
    if strlen( template ) > lastchunk-offset.
      append initial line to chunks assigning <chunk>.
      <chunk>-length = strlen( template ) - lastchunk-offset.
      <chunk>-offset = lastchunk-offset.
    endif.

  endmethod.


  method render.

    data: varvalue type string.

    field-symbols: <chunk> like line of chunks,
                   <var>   type data.

    loop at chunks assigning <chunk>.
      if <chunk>-replace = ''.
        concatenate output template+<chunk>-offset(<chunk>-length) into output respecting blanks.
      elseif <chunk>-variablename = ''.
        concatenate output <chunk>-value into output respecting blanks.
      else.
        varvalue = get_var_value( <chunk>-variablename ).
        concatenate output varvalue into output respecting blanks.
      endif.
    endloop.


  endmethod.


  method set_variable.

    data: var      like line of varvalues,
          td       type ref to cl_abap_typedescr,
          temp(50) type c.

    var-name = name.
    translate var-name to upper case.

    td = cl_abap_typedescr=>describe_by_data( value ).
    if td->kind = cl_abap_typedescr=>kind_elem.
      case td->type_kind.
        when cl_abap_typedescr=>typekind_float.
          if value < 1000000000.
            write value to temp style cl_abap_format=>o_simple.
          else.
            write value to temp style cl_abap_format=>o_engineering.
          endif.
          var-value = temp.
          condense var-value no-gaps.
        when cl_abap_typedescr=>typekind_date
          or cl_abap_typedescr=>typekind_time
          or cl_abap_typedescr=>typekind_decfloat
          or cl_abap_typedescr=>typekind_decfloat16
          or cl_abap_typedescr=>typekind_decfloat34
          or cl_abap_typedescr=>typekind_float.
          write value to temp.
          var-value = temp.
          condense var-value.
        when cl_abap_typedescr=>typekind_int
          or cl_abap_typedescr=>typekind_int1
          or '8' " cl_abap_typedescr=>typekind_int8
          or cl_abap_typedescr=>typekind_int2
          or cl_abap_typedescr=>typekind_hex.
          var-value = value.
          condense var-value.
        when others.
          var-value = value.
      endcase.
    endif.
    delete varvalues where name = var-name.
    append var to varvalues.

  endmethod.


  method varname.

    data: l type i.
    l = strlen( match ) - 2.
    varname = match+1(l).
    condense varname no-gaps.
    collect varname into varnames.

  endmethod.
ENDCLASS.
