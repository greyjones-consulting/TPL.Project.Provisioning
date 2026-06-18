@{
    # ====================== SOURCE COLUMN REFERENCE (Self-documenting) ======================
    # Exact columns from your Projects_Source of Truth list (as per your original instructions)
    SourceColumns = @{
        "Number"              = "Title"
        "Client"              = "Client"
        "Visit Site"          = "Visit_x0020_Site"
        "Stage"               = "field_3"
        "Project Status"      = "field_4"
        "Project Description" = "field_5"
        "Shortname"           = "field_6"
        "Start Date"          = "Start_x0020_Date"
        "Completion Date"     = "Completion_x0020_Date"
        "Fee Value"           = "field_11"               # Marketing only
        "Proposal Feedback"   = "field_17"               # Marketing only
        "Client Contact"      = "Client_x0020_Contact"   # lookup column (source)
    }

    # ====================== SOURCE OF TRUTH ======================
    SourceList    = @{
        Url        = "https://greyjonescoza.sharepoint.com/sites/ProjectPipeline-Database"
        ListName   = "Projects_SourceOfTruth"
        MatchField = "Title"
    }

    # ====================== TARGET LISTS (exact internal names from your original instructions) ======================
    TargetLists   = @{
        Marketing       = @{
            Url           = "https://greyjonescoza.sharepoint.com/sites/Marketing-LeadsandTenders"
            ListName      = "Project List"
            ColumnMapping = @{
                Title                 = "Title"
                Client                = "Client"
                Visit_x0020_Site      = "Visit_x0020_Site"
                field_3               = "Stage"
                field_4               = "Project_x0020_Status"
                field_5               = "Name"
                field_6               = "Shortname"
                Start_x0020_Date      = "Start_x0020_Date"
                Completion_x0020_Date = "Completion_x0020_Date"
                Client_x0020_Contact  = "Client_x0020_Contact"   # Marketing only
                field_11              = "Fee_x0020_Value"
                field_17              = "Proposal_x0020_Feedback"
            }
        }

        HR              = @{
            Url           = "https://greyjonescoza.sharepoint.com/sites/HR"
            ListName      = "Project List"
            ColumnMapping = @{
                Title                 = "Title"
                Client                = "Client"
                Visit_x0020_Site      = "Visit_x0020_Site"
                field_3               = "Stage"
                field_4               = "Project_x0020_Status"
                field_5               = "Name"
                field_6               = "Shortname"
                Start_x0020_Date      = "Start_x0020_Date"
                Completion_x0020_Date = "Completion_x0020_Date"
                Client_x0020_Contact  = "Contact"                # HR uses this name (per your instructions)
            }
        }

        ProjectPipeline = @{
            Url           = "https://greyjonescoza.sharepoint.com/sites/ProjectPipeline"
            ListName      = "Project List"
            ColumnMapping = @{
                Title                 = "Title"
                Client                = "Client"
                Visit_x0020_Site      = "Visit_x0020_Site"
                field_3               = "Stage"
                field_4               = "Project_x0020_Status"
                field_5               = "Name"
                field_6               = "Shortname"
                Start_x0020_Date      = "Start_x0020_Date"
                Completion_x0020_Date = "Completion_x0020_Date"
                Client_x0020_Contact  = "Contact"                # Project Pipeline uses this name (per your instructions)
            }
        }
    }

    LogPath       = "../../Logs/ProjectDataSync.log"
}