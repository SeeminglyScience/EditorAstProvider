# EditorAstProvider

EditorAstProvider is a PowerShell module that adds a PSDrive containing the abstract syntax tree (AST)
of the current file. Requires VSCode or other [PowerShellEditorServices](https://github.com/PowerShell/PowerShellEditorServices) enabled editor.

This project adheres to the Contributor Covenant [code of conduct](https://github.com/SeeminglyScience/EditorAstProvider/tree/master/docs/CODE_OF_CONDUCT.md).
By participating, you are expected to uphold this code. Please report unacceptable behavior to seeminglyscience@gmail.com.

## Features

- Browse the AST like the file system
- Content relevant item names where possible
- Table formatted output
- Works with *-Ast and *-ScriptExtent EditorServices commands

## Demo

![editor-ast-provider-demo](https://user-images.githubusercontent.com/24977523/31864403-ca6a75da-b72a-11e7-9ee9-a4d711e219c0.gif)

## Documentation

Check out our **[documentation](https://github.com/SeeminglyScience/EditorAstProvider/tree/master/docs/en-US/EditorAstProvider.md)** for information about how to use this project.

## Installation

### Gallery

```powershell
Install-Module EditorAstProvider -Scope CurrentUser
```

### Source

```powershell
git clone 'https://github.com/SeeminglyScience/EditorAstProvider.git'
Set-Location .\EditorAstProvider
Invoke-Build -Task Install
```

## Motivation

I absolutely adore the PowerShell AST, but it can be really difficult to navigate interactively if you
aren't already familar with how it all works.  The goal of this project is to create an AST exploration
experience that can be used by anyone familar with PowerShell.

It may have also been a good excuse to play with the new and very awesome [SHiPS](https://github.com/PowerShell/SHiPS) module :)

## Usage

### First example

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

## Contributions Welcome!

We would love to incorporate community contributions into this project.  If you would like to
contribute code, documentation, tests, or bug reports, please read our [Contribution Guide](https://github.com/SeeminglyScience/EditorAstProvider/tree/master/docs/CONTRIBUTING.md) to learn more.
