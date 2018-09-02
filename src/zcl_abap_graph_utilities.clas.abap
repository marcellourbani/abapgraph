class zcl_abap_graph_utilities definition public final create public .
  public section.
    class-methods: quoteifneeded importing raw            type string
                                 returning value(escaped) type string,
      show_in_browser importing graph type ref to zcl_abap_graph ,
      show_in_viewer  importing graph  type ref to zcl_abap_graph
                                viewer type ref to cl_gui_html_viewer,
      get_temp_file_url  returning value(r_result) type string.
  PRIVATE SECTION.
    CLASS-DATA uploadpath TYPE string.
    CLASS-DATA downloadpath TYPE string.
endclass.



class zcl_abap_graph_utilities implementation.
  method quoteifneeded.
    data: first type c.
    if raw <> ''.
      first = raw.
      if first <> '"'.
        concatenate '"' raw '"' into escaped respecting blanks.
      else.
        escaped = raw.
      endif.
    endif.

  endmethod.

  method show_in_browser.
    data: url      type string,
          contents type string,
          itab     type table of string.

    url = get_temp_file_url( ).
    contents = graph->generate_html_wrapper( ).
    append contents to itab.
    if url <>  ''.
      call function 'GUI_DOWNLOAD'
        exporting
          filename = url
        tables
          data_tab = itab
        exceptions
          others   = 22.
    endif.
    if sy-subrc <> 0 or url = ''.
      zcx_abap_graph=>raise( 'Error writing graph file' ).
    endif.

    cl_gui_frontend_services=>execute(
      exporting
        document               = url
        operation              = ' '
      exceptions
        file_extension_unknown = 1
        file_not_found         = 2
        path_not_found         = 3
        error_execute_failed   = 4
        error_no_gui           = 6
        others                 = 7 ).
    if sy-subrc <> 0.
      zcx_abap_graph=>raise( 'Failed to open URL' ).
    endif.

  endmethod.

  method show_in_viewer.
    data: contents type string,
          xstrcont type xstring,
          url      type w3url,
          xdatatab type table of w3_mime, " RAW255
          size     type int4.

    contents = graph->generate_html_wrapper( ).

    call function 'SCMS_STRING_TO_XSTRING'
      exporting
        text   = contents
      importing
        buffer = xstrcont
      exceptions
        others = 1.


    call function 'SCMS_XSTRING_TO_BINARY'
      exporting
        buffer        = xstrcont
      importing
        output_length = size
      tables
        binary_tab    = xdatatab.

    viewer->load_data(
      exporting
        size         = size
      importing
        assigned_url = url
      changing
        data_table   = xdatatab
      exceptions
        others       = 1 ) ##NO_TEXT.

    viewer->show_url( url ).
  endmethod.

  method get_temp_file_url.
    data: separator type c,
          guid      type guid_32.

    cl_gui_frontend_services=>get_file_separator(
      changing
        file_separator       = separator
      exceptions
        others               = 4 ).
    if sy-subrc = 0.
      cl_gui_frontend_services=>get_upload_download_path(
        changing
          upload_path                 =  uploadpath
          download_path               =  downloadpath
        exceptions
          others                      = 6 ).
    endif.
    if sy-subrc = 0.
      call function 'GUID_CREATE'
        importing
          ev_guid_32 = guid.

      if downloadpath is initial.

        concatenate guid '.html' into r_result.

      else.

        concatenate downloadpath separator guid '.html' into r_result.

      endif.
    endif.
  endmethod.

endclass.
