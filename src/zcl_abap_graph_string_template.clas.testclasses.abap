*"* use this source file for your ABAP unit test classes
include zabapgraph_string_template.
class dummy definition for testing.
  public section.
    class-data: instance type ref to dummy.
    data: strvalue type string value 'Astring',
          intvalue type i      value 1234,
          e070     type e070.
endclass.
class test_template definition for testing inheriting from cl_aunit_assert."#AU Risk_Level Harmless #AU Duration Short
  private section.
    methods: simple_values for testing,
             class_members for testing,
             indirect      for testing,
             escapes       for testing,
             fieldsymbols  for testing.


endclass.

class test_template implementation.

  method class_members.
    data: result type string,
          obj    type ref to dummy.

    agdefinitions.
    SET COUNTRY 'DE'. "for date formats
    create object obj.
    obj->e070-trkorr = 'NPLK900001'.
    obj->e070-as4date = '20100112'.

    agexpand 'A{obj->e070-trkorr}B{obj->intvalue}C{ obj->e070-as4date }D{obj->e070-as4time}.' result.
    assert_equals( act = result exp = 'ANPLK900001B1234C12.01.2010D00:00:00.' ).

  endmethod.

  method indirect.
    data: result type string.

    agdefinitions.
    SET COUNTRY 'US'. "for date formats
    create object dummy=>instance.
    dummy=>instance->e070-trkorr = 'NPLK900001'.
    dummy=>instance->e070-as4date = '20100112'.

    agexpand 'A{dummy=>instance->e070-trkorr}B{dummy=>instance->intvalue}C{ dummy=>instance->instance->e070-as4date }.' result.
    assert_equals( act = result exp = 'ANPLK900001B1234C01/12/2010.' ).

  endmethod.

  method simple_values.
    data: str1   type string value 'foo',
          float1 type f      value '1.25',
          result type string.

    agdefinitions.
    SET COUNTRY 'US'. "for decimal separators

    agexpand 'string={str1} float = { float1 }.' result.
    assert_equals( act = result exp = 'string=foo float = 1.25.' ).

    float1 = float1 * 1000000000.

    agexpand 'string={str1} float = { float1 }.' result.
    assert_equals( act = result exp = 'string=foo float = 1.25E+09.' ).

  endmethod.

  method escapes.
    data: str1     type string value 'foo',
          result   type string,
          expected type string.

    agdefinitions.

    agexpand '{str1} tab\tnewline\nff\fcrlf\r\n.' result.
    concatenate 'foo tab' cl_abap_char_utilities=>horizontal_tab
                'newline' cl_abap_char_utilities=>newline
                'ff' cl_abap_char_utilities=>form_feed
                'crlf' cl_abap_char_utilities=>cr_lf
                '.' into expected.
    assert_equals( act = result exp = expected ).

  endmethod.

  method fieldsymbols.
    data: str1     type string value 'foo',
          result   type string.

    field-symbols:<str> type any.

    agdefinitions.
    assign str1 to <str>.

    agexpand '{<str>}' result.

    assert_equals( act = result exp = 'foo' ).


  endmethod.

endclass.
