@{
    DefaultChannels            = @(
        @{
            DisplayName    = "Survey Data"
            Description    = "Engineering surveys, 3D models and point clouds."
            MembershipType = "Shared"
        },
        @{
            DisplayName    = "Project Documents"
            Description    = "For all controlled project WIP documents that will eventually be issued externally."
            MembershipType = "Standard"
        },
        @{
            DisplayName    = "Project Documents-Unmanaged"
            Description    = "For all user created WIP documents that will not be issued externally and do not require collaboration. Also consider as a user orientated document store for the project."
            MembershipType = "Standard"
        },
        @{
            DisplayName    = "Commercial Documents"
            Description    = "For all controlled commercial WIP documents that will eventually be issued externally."
            MembershipType = "Private"
        },
        @{
            DisplayName    = "Transmittals-Project"
            Description    = "All project documents that have been received and transmitted. Commercial documents excluded."
            MembershipType = "Shared"
        },
        @{
            DisplayName    = "Transmittals-Commercial"
            Description    = "All commercial documents that have been received and transmitted. Project documents excluded."
            MembershipType = "Shared"
        },
        @{
            DisplayName    = "Request for Information"
            Description    = "SharePoint List to document information requested."
            MembershipType = "Shared"
        }
    )

    DefaultDescriptionTemplate = "GreyJones team for the {0} project. The GreyJones project reference is {1}."
}