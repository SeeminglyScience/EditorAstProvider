---
external help file: EditorAstProvider-help.xml
online version: https://github.com/SeeminglyScience/EditorAstProvider/blob/master/docs/en-US/New-EditorAstPSDrive.md
schema: 2.0.0
---

# New-EditorAstPSDrive

## SYNOPSIS

Create the PSDrive 'CurrentFile' containing the AST of the currently opened file.

## SYNTAX

```powershell
New-EditorAstPSDrive
```

## DESCRIPTION

The New-EditorAstPSDrive function creates a PSDrive named 'CurrentFile' that lets you browse the AST
of the file currently open within a PowerShell Editor Services enabled editor.

Every item returned from the PSDrive has at minimum the properties 'Ast', 'Extent', and 'Name'. Some
item types may have additional convenience properties taken from the stored AST. Because these items
have both 'Ast' and 'Extent' properties they can be used with any *-Ast or *-ScriptExtent functions
from the PowerShellEditorServices.Commands module. Where possible, item names are relevant to the
AST type the item is based on. For example, a item that contains a FunctionDefinitionAst will be
named the same as the function it contains. If there isn't a relevant property to use as the name,
the AST type name will be used. For example, an item that contains a StringConstantExpressionAst
will be named StringConstantExpressionAst.

If an AST returns a name that is already used within the current container then a hyphen and an
incrementing digit will be appended to the name. For example if there are three
FunctionDefinitionAst objects for the function 'TestFunction' in the same container, the first will
be named 'TestFunction', the second 'TestFunction-2' and so on.

For performance reasons it is not recommended to use this provider for recursive searches of the
AST. Instead, take a look at using the Find-Ast function from PowerShellEditorServices.Commands.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
New-EditorAstPSDrive
Get-ChildItem CurrentFile:\
#     Container: CurrentFile:
#
# Mode Name                 AstType              Preview
# ---- ----                 -------              -------
# +    Root                 ScriptBlockAst       using namespace System.Collections.Generic...

Get-ChildItem CurrentFile:\ -Depth 2 -Filter *Item |
    Select-Object -First 1 |
    Get-ChildItem
#     Container: CurrentFile:\Root\EndBlock\SinglePropertyItem
#
# Mode Name                 AstType              Preview
# ---- ----                 -------              -------
# +    PropertyMap          PropertyMemberAst    hidden static [hashtable] $PropertyMap = @{...
# +    ReturnPropertyName   PropertyMemberAst    hidden [string] $ReturnPropertyName;
# +    SinglePropertyIte... FunctionMemberAst    SinglePropertyItem([Ast] $ast, [string] $returnP...
# +    GetChildItemImpl(0)  FunctionMemberAst    [object[]] GetChildItemImpl() {...
```

Creates the 'CurrentFile' PSDrive and browses the AST of the current file.

## PARAMETERS

## INPUTS

### None

This function does not accept input from the pipeline

## OUTPUTS

### Microsoft.PowerShell.SHiPS.SHiPSDrive

The PSDrive created by this function will be returned to the pipeline.

## NOTES

## RELATED LINKS
