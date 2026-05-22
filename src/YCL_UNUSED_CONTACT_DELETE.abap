*&---------------------------------------------------------------------*
*& Class        : YCL_UNUSED_CONTACT_DELETE
*& Description  : Identifies unused contact persons (BUT000-BUGROUP = 'ZCP')
*&                not referenced in V_CVI_CUST_CT_LI or V_CVI_VEND_CT_LI,
*&                and submits them for mass deletion via BUPA_TEST_DELETE.
*&---------------------------------------------------------------------*
CLASS ycl_unused_contact_delete DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    "! Main method: identifies and deletes unused contact persons.
    METHODS execute.

  PRIVATE SECTION.
    TYPES:
      ty_partner  TYPE but000-partner,
      ty_partners TYPE STANDARD TABLE OF ty_partner WITH DEFAULT KEY.

    "! Reads all partners from BUT000 where BUGROUP = 'ZCP'.
    METHODS get_zcp_partners
      RETURNING VALUE(rt_partners) TYPE ty_partners.

    "! Returns contact persons that exist in V_CVI_CUST_CT_LI.
    METHODS get_cust_contact_persons
      RETURNING VALUE(rt_partners) TYPE ty_partners.

    "! Returns contact persons that exist in V_CVI_VEND_CT_LI.
    METHODS get_vend_contact_persons
      RETURNING VALUE(rt_partners) TYPE ty_partners.

    "! Submits the unused partners to BUPA_TEST_DELETE for mass deletion.
    METHODS submit_for_deletion
      IMPORTING it_partners TYPE ty_partners.

ENDCLASS.


CLASS ycl_unused_contact_delete IMPLEMENTATION.

  METHOD execute.
    DATA(lt_zcp_partners) = get_zcp_partners( ).

    IF lt_zcp_partners IS INITIAL.
      MESSAGE 'No contact persons found with account group ZCP.' TYPE 'I'.
      RETURN.
    ENDIF.

    DATA(lt_cust_contacts) = get_cust_contact_persons( ).
    DATA(lt_vend_contacts) = get_vend_contact_persons( ).

    " Merge both sets of used contact persons into a single sorted lookup table
    DATA lt_used_contacts TYPE ty_partners.
    APPEND LINES OF lt_cust_contacts TO lt_used_contacts.
    APPEND LINES OF lt_vend_contacts TO lt_used_contacts.
    SORT lt_used_contacts.
    DELETE ADJACENT DUPLICATES FROM lt_used_contacts.

    " Collect ZCP partners not present in either contact-person table
    DATA lt_unused TYPE ty_partners.
    LOOP AT lt_zcp_partners INTO DATA(lv_partner).
      READ TABLE lt_used_contacts WITH KEY table_line = lv_partner
                                  TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        APPEND lv_partner TO lt_unused.
      ENDIF.
    ENDLOOP.

    IF lt_unused IS INITIAL.
      MESSAGE 'All ZCP contact persons are in use. Nothing to delete.' TYPE 'I'.
      RETURN.
    ENDIF.

    submit_for_deletion( lt_unused ).
  ENDMETHOD.


  METHOD get_zcp_partners.
    SELECT partner
      FROM but000
      INTO TABLE @rt_partners
      WHERE bugroup = 'ZCP'.
  ENDMETHOD.


  METHOD get_cust_contact_persons.
    SELECT contactperson
      FROM v_cvi_cust_ct_li
      INTO TABLE @rt_partners.
  ENDMETHOD.


  METHOD get_vend_contact_persons.
    SELECT contactperson
      FROM v_cvi_vend_ct_li
      INTO TABLE @rt_partners.
  ENDMETHOD.


  METHOD submit_for_deletion.
    " Build a ranges table for the PARTNER select-option of BUPA_TEST_DELETE
    DATA lt_partner_range TYPE RANGE OF but000-partner.

    LOOP AT it_partners INTO DATA(lv_partner).
      APPEND VALUE #( sign   = 'I'
                      option = 'EQ'
                      low    = lv_partner ) TO lt_partner_range.
    ENDLOOP.

    SUBMIT bupa_test_delete
      WITH partner IN lt_partner_range
      AND RETURN.
  ENDMETHOD.

ENDCLASS.
