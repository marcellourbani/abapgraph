class zcx_abap_graph definition public inheriting from cx_no_check create public .

  public section.

    constants zcx_abap_graph type sotr_conc value '0242AC1100021EE8AB9BDF0D95850806' ##NO_TEXT.
    class-methods raise
      importing
        previous     like previous optional
        errormessage type csequence.
    data errormessage type string .

    methods constructor
      importing
        !textid       like textid optional
        !previous     like previous optional
        !errormessage type string optional .
  protected section.
  private section.
endclass.



class zcx_abap_graph implementation.

  method raise.

    data: exc         type ref to zcx_abap_graph,
          messagetext type string.

    messagetext = errormessage.

    create object exc
      exporting
        textid       = zcx_abap_graph
        previous     = previous
        errormessage = messagetext.

    raise exception exc.

  endmethod.


  method constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( textid = textid previous = previous ).
    if textid is initial.
      me->textid = zcx_abap_graph .
    endif.
    me->errormessage = errormessage .
  endmethod.
endclass.
