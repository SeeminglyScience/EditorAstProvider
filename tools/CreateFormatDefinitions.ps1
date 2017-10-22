#requires -version 5.1

using namespace System.Management.Automation
using namespace System.Management.Automation.Runspaces
using namespace System.Collections.Generic

[CmdletBinding()]
param(
    [string] $Destination
)
end {
    $groupByPathControl = [CustomControl]::Create().
        StartEntry().
            StartFrame(4).
                AddText('Container: ').
                AddScriptBlockExpressionBinding({
                    $PSItem.PSParentPath.Replace(
                        'Microsoft.PowerShell.SHiPS\SHiPS::EditorAstProvider#CurrentFileAst',
                        'CurrentFile:')
                }).
                AddNewline().
            EndFrame().
        EndEntry().
    EndControl()

    $astItemTableControl = [TableControl]::Create().
        GroupByProperty('PSParentPath', $groupByPathControl).
        AddHeader('Left', 4, 'Mode').
        AddHeader('Left', 20).
        AddHeader('Left', 20).
        AddHeader('Left', $null, 'Preview').
        StartRowDefinition().
            AddPropertyColumn('SSItemMode').
            AddPropertyColumn('Name').
            AddPropertyColumn('AstType').
            AddScriptBlockColumn({ $PSItem.Extent.Text }).
        EndRowDefinition().
    EndTable()

    [ExtendedTypeDefinition[]] $EDITORASTPROVIDER_FORMAT_PS1XML = & {
        [ExtendedTypeDefinition]::new(
            'AstContainer',
            [FormatViewDefinition]::new(
                'AstContainer',
                $astItemTableControl) -as [FormatViewDefinition[]])

        [ExtendedTypeDefinition]::new(
            'AstLeaf',
            [FormatViewDefinition]::new(
                'AstLeaf',
                $astItemTableControl) -as [FormatViewDefinition[]])
    }

    $projectName = $PSScriptRoot | Split-Path | Split-Path -Leaf
    $destinationFile = Join-Path $Destination -ChildPath "$projectName.format.ps1xml"
    $exportFormatDataSplat = @{
        InputObject        = $EDITORASTPROVIDER_FORMAT_PS1XML
        IncludeScriptBlock = $true
        Path               = $destinationFile
    }

    Export-FormatData @exportFormatDataSplat

    # & $EDITORASTPROVIDER_FORMAT_PS1XML | ForEach-Object {
    #     $destinationFile = Join-Path $Destination -ChildPath $PSItem.TypeName
    #     $destinationFile += '.format.ps1xml'
    #     Export-FormatData -InputObject $PSItem -Path $destinationFile -IncludeScriptBlock
    # }
}
