*&---------------------------------------------------------------------*
*& Program      : YMMR_UNUSED_CONTACT_DEL
*& Description  : Entry point for deleting unused contact persons.
*&                Instantiates YCL_UNUSED_CONTACT_DELETE and calls EXECUTE.
*&
*& Logic overview:
*&   1. Read all BUT000 entries where BUGROUP = 'ZCP'.
*&   2. Check each partner against V_CVI_CUST_CT_LI-CONTACTPERSON and
*&      V_CVI_VEND_CT_LI-CONTACTPERSON.
*&   3. Partners not found in either table are submitted to BUPA_TEST_DELETE
*&      for mass deletion.
*&---------------------------------------------------------------------*
REPORT ymmr_unused_contact_del.

START-OF-SELECTION.
  DATA(lo_handler) = NEW ycl_unused_contact_delete( ).
  lo_handler->execute( ).
