<!-- To be used when creating a new Project Team for a TPL Fire Upgrade Project. --> TPL.Project.Provisioning
<! The CDR channel is provisonined differently to the other channels that use content types and view defintions.
The CDR channel requires generation of an .xml file that duplicates the list and applicable entries, and is used during the Team provisioning process to apply to the newly created
CDR channel in the target team. To update the .xml file that will be used in the template, the Clone-CDRChannel.ps1 file must be run. This script uses the configFile_CDR.json inputs
to create the .xml file. Any changes required to the .xml file must be made in the JSON config file prior to running the Clone-CDRChannel script.>