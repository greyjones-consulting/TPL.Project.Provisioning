@{
    # =========================================================================
    # CDR Reference Lists - Data Sync Configuration
    # Used by Import-CDRListData.ps1
    # =========================================================================

    CDRReferenceLists = @{

        "TPL_Disciplines"   = @{
            Fields = @("Title", "field_1")          # Title + Discipline Description
        }

        "TPL_DocumentTypes" = @{
            Fields = @(
                "Title",
                "field_1",                              # Description
                "field_2",                              # Additional Description
                "field_3",                              # Class
                "Document_x0020_Type_x0020__x0028",     # Document Type (Display)
                "NumberingPath0",
                "EmployerExternalDocumentNumber"
            )
        }

        "TPL_Revisions"     = @{
            Fields = @("Title")
        }
    }
}