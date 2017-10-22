---
Module Name: EditorAstPSDrive
Module Guid: 4725a33e-7393-4306-9fa2-f5da58831c75
Download Help Link:
Help Version: 1.0.0
Locale: en-US
---

# EditorAstPSDrive Module

## Description

EditorAstProvider is a PowerShell module that adds a PSDrive containing the abstract syntax tree (AST)
of the current file. Requires VSCode or other PowerShellEditorServices enabled editor.

## EditorAstPSDrive Cmdlets

### [New-EditorAstPSDrive](New-EditorAstPSDrive.md)

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
