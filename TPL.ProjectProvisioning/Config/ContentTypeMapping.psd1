@{
    # ====================== CONTENT TYPE DEFINITIONS ======================
    # These stay at the top level so you can reference them easily anywhere
    GreyJonesDocumentCT          = "0x010100F666B850A06DF84C94E08372324C24B4" # GreyJones Document Content Type
    GreyJonesEngCentreClientCT   = "0x010100F1EF89CD411AB342952CE0C0EB2E1950" #
    GreyJonesEngCentreStandardCT = "0x01010019AE4C6A9F118E49B1F13BA3B8ADE331"
    GreyJonesImageCT             = "0x010100F666B850A06DF84C94E08372324C24B403"
    TransmittalDocumentCT        = "0x010100F666B850A06DF84C94E08372324C24B402"
    TransmittalDocumentSet       = "0x0120D520006F33CE761C8455468E76988DC87A8835"
    RFIContentType               = "0x0100607ACBBCE270474F8BBEA3DBD7D21761"

    # ====================== CHANNEL-SPECIFIC CONFIGURATIONS ======================
    # This is the big improvement – everything for one channel lives together
    # Add new channels here later with zero changes to your .ps1 files
    ChannelConfigurations        = @{

        ProjectDocuments       = @{
            LibraryName            = "Project Documents"
            Description            = "For all controlled project WIP documents that will eventually be issued externally."
            ContentTypeKeys        = @("GreyJonesDocumentCT")
            DefaultContentTypeKey  = "GreyJonesDocumentCT"
            DefaultContentTypeName = "GreyJones Document Content Type"
            ViewNames              = @("GreyJones Documents", "Internal Document Numbers")
            DefaultView            = "GreyJones Documents"
            SourceSiteForViews     = "10071"
            EnableFolderCreation   = $false
        }

        CommercialDocuments    = @{
            LibraryName            = "Commercial Documents"
            Description            = "For all controlled commercial WIP documents that will eventually be issued externally."
            ContentTypeKeys        = @("GreyJonesDocumentCT")
            DefaultContentTypeKey  = "GreyJonesDocumentCT"
            DefaultContentTypeName = "GreyJones Document Content Type"
            ViewNames              = @("GreyJones Documents", "Internal Document Numbers")
            DefaultView            = "GreyJones Documents"
            SourceSiteForViews     = "10071-CommercialDocuments"
            EnableFolderCreation   = $false
        }

        SurveyData             = @{
            LibraryName            = "Survey Data"
            Description            = "Engineering surveys, 3D models and point clouds."
            ContentTypeKeys        = @("GreyJonesImageCT", "GreyJonesDocumentCT")
            DefaultContentTypeKey  = "GreyJonesImageCT"
            DefaultContentTypeName = "GreyJones Image Content Type"
            ViewNames              = @("GreyJones Images", "GreyJones Documents", "Internal Document Numbers")
            DefaultView            = "GreyJones Images"
            SourceSiteForViews     = "10071GreyJonesProjectTemplate-SurveyData"
            EnableFolderCreation   = $false
        }

        TransmittalsProject    = @{
            LibraryName            = "Transmittals-Project"
            Description            = "All project documents that have been received and transmitted. Commercial documents excluded."
            ContentTypeKeys        = @("TransmittalDocumentCT", "TransmittalDocumentSet")
            DefaultContentTypeKey  = "TransmittalDocumentCT"
            DefaultContentTypeName = "Transmittal Document Content Type"
            ViewNames              = @("Document Set", "Document Set Flat", "Transmitted Documents", "Transmitted Documents MetaData")
            DefaultView            = "Document Set"
            SourceSiteForViews     = "10071GreyJonesProjectTemplate-Transmittals-Project"
            EnableFolderCreation   = $false
        }

        TransmittalsCommercial = @{
            LibraryName            = "Transmittals-Commercial"
            Description            = "All commercial documents that have been received and transmitted. Project documents excluded."
            ContentTypeKeys        = @("TransmittalDocumentCT", "TransmittalDocumentSet")
            DefaultContentTypeKey  = "TransmittalDocumentCT"
            DefaultContentTypeName = "Transmittal Document Content Type"
            ViewNames              = @("Document Set", "Document Set Flat", "Transmitted Documents", "Transmitted Documents MetaData")
            DefaultView            = "Document Set"
            SourceSiteForViews     = "10071GreyJonesProjectTemplate-Transmittals-Commercial"
            EnableFolderCreation   = $false
        }

        RequestForInformation  = @{
            LibraryName            = $null
            Description            = "SharePoint List to document information requested."
            ContentTypeKeys        = @("RFIContentType")
            DefaultContentTypeKey  = "RFIContentType"
            DefaultContentTypeName = "Request for Information Content Type"
            ViewNames              = @()                     # RFI uses site template
            DefaultView            = $null
            SourceSiteForViews     = $null # 10071GreyJonesProjectTemplate-RequestforInformation
            EnableFolderCreation   = $false
        }
    }

    # ====================== SHARED SETTINGS ======================
    ChannelBaseUrl               = "https://greyjonescoza.sharepoint.com/sites/"
}