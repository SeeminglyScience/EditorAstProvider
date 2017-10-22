using namespace System.Collections.Generic
using namespace System.IO
using namespace System.Management.Automation
using namespace System.Management.Automation.Language
using namespace Microsoft.PowerShell.EditorServices.Extensions
using namespace Microsoft.PowerShell.SHiPS

Import-LocalizedData -BindingVariable Strings -FileName Strings -ErrorAction Ignore

# Make-shift property accessor
class AstItemCodeMethods {
    static [string] AstTypeCodeProperty([psobject] $instance) {
        if (-not $instance.Ast) {
            return 'None'
        }

        return $instance.Ast.GetType().Name
    }
}

class AstTypeParameter {
    [Parameter()]
    [ValidateSet(
        'ErrorStatementAst', 'ErrorExpressionAst', 'ScriptBlockAst', 'ParamBlockAst', 'NamedBlockAst',
        'NamedAttributeArgumentAst', 'AttributeBaseAst', 'AttributeAst', 'TypeConstraintAst',
        'ParameterAst', 'StatementBlockAst', 'StatementAst', 'TypeDefinitionAst', 'UsingStatementAst',
        'MemberAst', 'PropertyMemberAst', 'FunctionMemberAst', 'FunctionDefinitionAst',
        'IfStatementAst', 'DataStatementAst', 'LabeledStatementAst', 'LoopStatementAst',
        'ForEachStatementAst', 'ForStatementAst', 'DoWhileStatementAst', 'DoUntilStatementAst',
        'WhileStatementAst', 'SwitchStatementAst', 'CatchClauseAst', 'TryStatementAst',
        'TrapStatementAst', 'BreakStatementAst', 'ContinueStatementAst', 'ReturnStatementAst',
        'ExitStatementAst', 'ThrowStatementAst', 'PipelineBaseAst', 'PipelineAst', 'CommandElementAst',
        'CommandParameterAst', 'CommandBaseAst', 'CommandAst', 'CommandExpressionAst', 'RedirectionAst',
        'MergingRedirectionAst', 'FileRedirectionAst', 'AssignmentStatementAst', 'ConfigurationDefinitionAst',
        'DynamicKeywordStatementAst', 'ExpressionAst', 'BinaryExpressionAst', 'UnaryExpressionAst',
        'BlockStatementAst', 'AttributedExpressionAst', 'ConvertExpressionAst', 'MemberExpressionAst',
        'InvokeMemberExpressionAst', 'BaseCtorInvokeMemberExpressionAst', 'TypeExpressionAst',
        'VariableExpressionAst', 'ConstantExpressionAst', 'StringConstantExpressionAst',
        'ExpandableStringExpressionAst', 'ScriptBlockExpressionAst', 'ArrayLiteralAst', 'HashtableAst',
        'ArrayExpressionAst', 'ParenExpressionAst', 'SubExpressionAst', 'UsingExpressionAst',
        'IndexExpressionAst')]
    [string] $AstType
}

class AstContainerBase : SHiPSDirectory {
    static [hashtable] $TypeMap = @{
        [ScriptBlockAst] = [ScriptBlockAstItem]
        [TypeDefinitionAst] = [TypeDefinitionAstItem]
        [FunctionMemberAst] = [FunctionMemberAstItem]
        [PropertyMemberAst] = [PropertyMemberAstItem]
        [AssignmentStatementAst] = [AssignmentStatementAstItem]
        [FunctionDefinitionAst] = [FunctionDefinitionAstItem]
        [CommandAst] = [CommandAstItem]
        [ParameterAst] = [ParameterAstItem]
        [NamedBlockAst] = [NamedBlockAstItem]
        [BinaryExpressionAst] = [BinaryExpressionAstItem]
        [UnaryExpressionAst] = [UnaryExpressionAstItem]
        [AttributedExpressionAst] = [AttributedExpressionAstItem]
        [ConvertExpressionAst] = [ConvertExpressionAstItem]
        [MemberExpressionAst] = [MemberExpressionAstItem]
        [InvokeMemberExpressionAst] = [InvokeMemberExpressionAstItem]
        [BaseCtorInvokeMemberExpressionAst] = [InvokeMemberExpressionAstItem]
        [IndexExpressionAst] = [IndexExpressionAstItem]
        [NamedAttributeArgumentAst] = [NamedAttributeArgumentAstItem]
        [AttributeAst] = [AttributeAstItem]
        [DataStatementAst] = [DataStatementAstItem]
        [ForEachStatementAst] = [ForEachStatementAstItem]
        [ForStatementAst] = [ForStatementAstItem]
        [DoWhileStatementAst] = [LoopStatementAstItem]
        [DoUntilStatementAst] = [LoopStatementAstItem]
        [WhileStatementAst] = [LoopStatementAstItem]
        [TryStatementAst] = [TryStatementAstItem]
        [ConfigurationDefinitionAst] = [ConfigurationDefinitionAstItem]
        [UsingStatementAst] = [UsingStatementAstItem]
        [SwitchStatementAst] = [SwitchStatementAstItem]
        [IfStatementAst] = [IfStatementAstItem]
        [HashtableAst] = [HashtableAstItem]
        [TypeConstraintAst] = [TypeConstraintAstItem]
        [ConstantExpressionAst] = [ConstantExpressionAstItem]
        [StringConstantExpressionAst] = [StringConstantExpressionAstItem]
        [CommandParameterAst] = [CommandParameterAstItem]
        [VariableExpressionAst] = [VariableExpressionAstItem]
    };

    [Ast] $Ast;
    [IScriptExtent] $Extent;

    AstContainerBase() : base($this.GetType().Name) { }
    AstContainerBase([string] $name) : base($name) { }

    static [SHiPSBase] CreateAstItem([Ast] $item) {
        $astType = $item.GetType()
        if ($itemType = [AstContainerBase]::TypeMap[$astType]) {
            return $itemType::new($item)
        }

        if ($itemType = [SinglePropertyItem]::PropertyMap[$astType]) {
            return [SinglePropertyItem]::new($item, $itemType)
        }

        return [AstContainer]::new($item)
    }

    hidden static [void] AssertCommandsModuleLoaded() {
        if ([CurrentFileAst]::IsCommandsLoaded) {
            return
        }

        $commandsModule = Get-Module PowerShellEditorServices.Commands -ErrorAction Ignore
        if ($commandsModule) {
            [CurrentFileAst]::IsCommandsLoaded = $true
            return
        }

        if ($path = [CurrentFileAst]::CommandsModulePath) {
            Import-Module $path -Global
            [CurrentFileAst]::IsCommandsLoaded = $true
            return
        }

        $exception = [PSInvalidOperationException]::new($script:Strings.CannotLoadPSESCommands)
        throw [ErrorRecord]::new(
            <# exception:     #> $exception,
            <# errorId:       #> 'CannotLoadPSESCommands',
            <# errorCategory: #> 'ObjectNotFound',
            <# targetObject:  #> $null)
    }

    [object[]] GetChildItem() {
        [AstContainerBase]::AssertCommandsModuleLoaded()
        $nameCounts = [Dictionary[string, int]]::new()
        return $this.GetRawChildItem().ForEach{
            if (-not $PSItem) {
                return
            }

            if ([string]::IsNullOrEmpty($PSItem.Name)) {
                if ($PSItem.Ast) {
                    $PSItem.Name = $PSItem.Ast.GetType().Name
                } else {
                    $PSItem.Name = $PSItem.GetType().Name
                }
            }

            $name = ($PSItem.Name.
                Split([Path]::InvalidPathChars) -join
                '') -replace
                '[\[\]]'

            if (-not $nameCounts.TryGetValue($name, [ref]$null)) {
                $nameCounts.Add($name, 1)
                $PSItem.Name = $name
                return $PSItem
            }

            $nameCounts[$name]++
            $PSItem.Name = $name + '-' + $nameCounts[$name]
            return $PSItem
        }
    }

    hidden [object[]] GetRawChildItem() {
        $astType = ('System.Management.Automation.Language.' +
            $this.ProviderContext.DynamicParameters.AstType) -as
            [type]

        return $this.
            GetChildItemImpl().
            ForEach{
                if ($PSItem -is [Ast]) {
                    return [AstContainerBase]::CreateAstItem($PSItem)
                }

                return $PSItem
            }.
            Where{ -not $astType -or $PSItem.Ast -is $astType }
    }

    <# abstract #> [object[]] GetChildItemImpl() {
        throw [NotImplementedException]::new()
    }

    [object] GetChildItemDynamicParameters() {
        return [AstTypeParameter]::new()
    }

    [string] ToString() {
        return $this.Ast.ToString()
    }
}

class AstContainer : AstContainerBase {
    AstContainer ([Ast] $ast) : base($ast.ForEach('GetType').Name) {
        $this.Ast = $ast
        $this.Extent = $ast.Extent
    }

    AstContainer ([Ast] $ast, [string] $name) : base($name) {
        $this.Ast = $ast
        $this.Extent = $ast.Extent
    }

    [object[]] GetChildItemImpl() {
        return $this.
            Ast.
            FindAll({ $true }, $false).
            Where({ $PSItem -ne $this.Ast }, 'SkipUntil')
    }

    [object] GetChildItemDynamicParameters() {
        return [AstTypeParameter]::new()
    }
}

class SinglePropertyItem : AstContainer {
    hidden static [hashtable] $PropertyMap = @{
        [PipelineAst] = 'PipelineElements'
        [ParamBlockAst] = 'Parameters'
        [StatementBlockAst] = 'Statements'
        [ScriptBlockExpressionAst] = 'ScriptBlock'
        [CommandExpressionAst] = 'Expression'
        [ExpandableStringExpressionAst] = 'NestedExpressions'
        [ArrayLiteralAst] = 'Elements'
        [ArrayExpressionAst] = 'SubExpression'
        [ParenExpressionAst] = 'Pipeline'
        [SubExpressionAst] = 'SubExpression'
        [UsingExpressionAst] = 'SubExpression'
        [ThrowStatementAst] = 'Pipeline'
        [ReturnStatementAst] = 'Pipeline'
        [ExitStatementAst] = 'Pipeline'
        [DynamicKeywordStatementAst] = 'CommandElements'
        [CatchClauseAst] = 'Body'
    }

    hidden [string] $ReturnPropertyName;

    SinglePropertyItem([Ast] $ast, [string] $returnProperty) : base($ast) {
        if ([string]::IsNullOrEmpty($returnProperty)) {
            $returnProperty = [SinglePropertyItem]::PropertyMap[$ast.GetType()]
        }

        $this.ReturnPropertyName = $returnProperty
    }

    [object[]] GetChildItemImpl() {
        return $this.Ast.($this.ReturnPropertyName)
    }
}

class CurrentFileAst : AstContainerBase {
    hidden static [string] $GetEditorObjectEventName = 'EditorAstProvider.GetEditorObject'
    hidden static [EditorObject] $EditorObject;
    hidden static [string] $CommandsModulePath;
    hidden static [bool] $IsCommandsLoaded;

    CurrentFileAst() : base($this.GetType()) { $this.Init() }
    CurrentFileAst([string] $name) : base($name) { $this.Init() }

    hidden [void] Init() {
        if ([CurrentFileAst]::EditorObject -and [CurrentFileAst]::CommandsModulePath) {
            return
        }

        # The provider runs in a different runspace, so we need to get the
        # editor object (psEditor) and Commands module path from the main
        # runspace.
        $rs = Get-Runspace 2
        $rs.Events.SubscribeEvent(
            <# source:           #> $null,
            <# eventName:        #> [CurrentFileAst]::GetEditorObjectEventName,
            <# sourceIdentifier: #> [CurrentFileAst]::GetEditorObjectEventName,
            <# data:             #> $null,
            <# scriptblock:      #> {
                $sender::EditorObject = Get-Variable psEditor -Scope Global -ValueOnly
                $commandsModule = Get-Module PowerShellEditorServices.Commands
                $joinPathSplat = @{
                    Path      = $commandsModule.ModuleBase
                    ChildPath = 'PowerShellEditorServices.Commands.psd1'
                }

                $sender::CommandsModulePath = Join-Path @joinPathSplat
            },
            <# supportEvent:     #> $true,
            <# forwardEvent:     #> $false,
            <# maxTriggerCount:  #> 1)

        $rs.Events.GenerateEvent(
            <# sourceIdentifier:                 #> [CurrentFileAst]::GetEditorObjectEventName,
            <# sender:                           #> $this.GetType(),
            <# args:                             #> @(),
            <# extraData:                        #> $null,
            <# processInCurrentThread:           #> $false,
            <# waitForCompletionInCurrentThread: #> $true)
    }

    [object[]] GetChildItemImpl() {
        if (-not [CurrentFileAst]::EditorObject) {
            return @()
        }

        Set-Variable psEditor -Scope Global -Value ([CurrentFileAst]::EditorObject)
        return [ScriptBlockAstItem]::new(
            [CurrentFileAst]::EditorObject.GetEditorContext().CurrentFile.Ast,
            'Root')
    }
}

class ScriptBlockAstItem : AstContainer {
    hidden static [string[]] $NamedBlockKinds = (
        'DynamicParamBlock',
        'BeginBlock',
        'ProcessBlock',
        'EndBlock')

    ScriptBlockAstItem([Ast] $ast) : base($ast) { }
    ScriptBlockAstItem([Ast] $ast, [string] $name) : base($ast, $name) { }

    [object[]] GetChildItemImpl() {
        return . {
            [ScriptBlockAst] $sbAst = $this.Ast

            # yield
            $sbAst.ParamBlock
            foreach ($blockKind in [ScriptBlockAstItem]::NamedBlockKinds) {
                if (-not $sbAst.$blockKind) {
                    continue
                }

                # yield
                [NamedBlockAstItem]::new(
                    $sbAst.$blockKind,
                    $blockKind)
            }
        }
    }
}

class TypeDefinitionAstItem : AstContainer {
    TypeDefinitionAstItem([TypeDefinitionAst] $ast) : base($ast, $ast.Name) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Members
    }
}

class FunctionMemberAstItem : AstContainer {
    FunctionMemberAstItem([FunctionMemberAst] $ast)
        : base($ast, $ast.Name + '(' + $ast.Parameters.Count + ')')
    { }

    [object[]] GetChildItemImpl() {
        return . {
            $this.Ast.ReturnType
            $this.Ast.Parameters
            [ScriptBlockAstItem]::new($this.Ast.Body, 'Body')
        }
    }
}

class PropertyMemberAstItem : AstContainer {
    PropertyMemberAstItem([PropertyMemberAst] $ast) : base($ast, $ast.Name) { }

    [object[]] GetChildItemImpl() {
        return . {
            $this.Ast.PropertyType
            $this.Ast.Attributes
            $this.Ast.InitialValue
        }
    }
}

class AssignmentStatementAstItem : AstContainer {
    AssignmentStatementAstItem([AssignmentStatementAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Left, $this.Ast.Right
    }
}

class FunctionDefinitionAstItem : AstContainer {
    FunctionDefinitionAstItem([FunctionDefinitionAst] $ast) : base($ast, $ast.Name) { }

    [object[]] GetChildItemImpl() {
        return [ScriptBlockAstItem]::new($this.Ast.Body, 'Body')
    }
}

class CommandAstItem : AstContainer {
    CommandAstItem([CommandAst] $ast) : base($ast, $ast.GetCommandName()) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.CommandElements
    }
}

class ParameterAstItem : AstContainer {
    ParameterAstItem([ParameterAst] $ast) : base($ast, $ast.Name.VariablePath.UserPath) { }

    [object[]] GetChildItemImpl() {
        return . {
            $this.Ast.Attributes
            $this.Ast.Name
            $this.Ast.DefaultValue
        }
    }
}

class NamedBlockAstItem : AstContainer {
    [TokenKind] $BlockKind;
    [bool] $IsUnnamed;

    NamedBlockAstItem([Ast] $ast, [string] $name) : base($ast, $name) {
        $this.BlockKind = $ast.BlockKind
        $this.IsUnnamed = $ast.Unnamed
    }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Statements
    }
}

class BinaryExpressionAstItem : AstContainer {
    [TokenKind] $Operator;

    BinaryExpressionAstItem([BinaryExpressionAst] $ast) : base($ast) {
        $this.Operator = $ast.Operator
    }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Left, $this.Ast.Right
    }
}

class UnaryExpressionAstItem : AstContainer {
    [TokenKind] $TokenKind;

    UnaryExpressionAstItem([UnaryExpressionAst] $ast) : base($ast) {
        $this.TokenKind = $ast.TokenKind
    }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Child
    }
}

class AttributedExpressionAstItem : AstContainer {
    AttributedExpressionAstItem([AttributedExpressionAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Attribute, $this.Ast.Child
    }
}

class ConvertExpressionAstItem : AstContainer {
    ConvertExpressionAstItem([ConvertExpressionAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Type, $this.Ast.Attribute, $this.Ast.Child
    }
}

class MemberExpressionAstItem : AstContainer {
    [bool] $IsStatic;

    MemberExpressionAstItem([MemberExpressionAst] $ast) : base($ast) {
        $this.IsStatic = $true
    }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Expression, $this.Ast.Member
    }
}

class InvokeMemberExpressionAstItem : MemberExpressionAstItem {
    InvokeMemberExpressionAstItem([InvokeMemberExpressionAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return . {
            $this.Ast.Expression
            $this.Ast.Member
            $this.Ast.Arguments
        }
    }
}

class IndexExpressionAstItem : AstContainer {
    IndexExpressionAstItem([IndexExpressionAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Target, $this.Ast.Index
    }
}

class NamedAttributeArgumentAstItem : AstContainer {
    [bool] $ExpressionOmitted;
    NamedAttributeArgumentAstItem([NamedAttributeArgumentAst] $ast) : base($ast, $ast.ArgumentName) {
        $this.ExpressionOmitted = $ast.ExpressionOmitted
    }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Argument
    }
}

class AttributeAstItem : AstContainer {
    AttributeAstItem([AttributeAst] $ast) : base($ast, $ast.TypeName.Name) { }

    [object[]] GetChildItemImpl() {
        return . {
            $this.Ast.PositionalArguments
            $this.Ast.NamedArguments
        }
    }
}

class DataStatementAstItem : AstContainer {
    DataStatementAstItem([DataStatementAst] $ast) : base($ast, $ast.Variable) { }

    [object[]] GetChildItemImpl() {
        return . {
            $this.Ast.CommandsAllowed
            $this.Ast.Body
        }
    }
}

class ForEachStatementAstItem : AstContainer {
    ForEachStatementAstItem([ForEachStatementAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Variable, $this.Ast.Condition, $this.Ast.ThrottleLimit, $this.Ast.Body
    }
}

class ForStatementAstItem : AstContainer {
    ForStatementAstItem([ForStatementAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Initializer, $this.Ast.Iterator, $this.Ast.Body, $this.Ast.Condition
    }
}

class LoopStatementAstItem : AstContainer {
    LoopStatementAstItem([LoopStatementAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Body, $this.Ast.Condition
    }
}

class TryStatementAstItem : AstContainer {
    TryStatementAstItem([TryStatementAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return . {
            $this.Ast.Body
            $this.Ast.CatchClauses
            $this.Ast.Finally
        }
    }
}

class ConfigurationDefinitionAstItem : AstContainer {
    ConfigurationDefinitionAstItem([ConfigurationDefinitionAst] $ast)
        : base($ast, $ast.InstanceName) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.InstanceName, $this.Ast.Body
    }
}

class UsingStatementAstItem : AstContainer {
    [UsingStatementKind] $UsingStatementKind;

    UsingStatementAstItem([UsingStatementAst] $ast) : base($ast) {
        $this.UsingStatementKind = $ast.UsingStatementKind
    }

    [object[]] GetChildItemImpl() {
        return $this.Ast.Name, $this.Ast.Alias, $this.Ast.ModuleSpecification
    }
}

class SwitchStatementAstItem : AstContainer {
    SwitchStatementAstItem([SwitchStatementAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return . {
            $this.Ast.Condition
            $this.Ast.Clauses.ForEach{
                # yield
                [IfStatementClauseItem]::new($PSItem, [TokenKind]::Switch)
            }

            if ($this.Ast.Default) {
                # yield
                [IfStatementClauseItem]::new(
                    [Tuple[ExpressionAst, StatementBlockAst]]::new(
                        $null,
                        $this.Ast.Default),
                    [TokenKind]::Else)
            }
        }
    }
}

class IfStatementAstItem : AstContainer {
    IfStatementAstItem([IfStatementAst] $ast) : base ($ast) { }

    [object[]] GetChildItemImpl() {
        return . {
            $first, $rest = $this.Ast.Clauses.Where({ $true }, 'Split', 1)

            # yield
            [IfStatementClauseItem]::new($first[0], [TokenKind]::If)
            $rest.ForEach{
                # yield
                [IfStatementClauseItem]::new($PSItem, [TokenKind]::ElseIf)
            }

            if ($this.Ast.ElseClause) {
                # yield
                [IfStatementClauseItem]::new(
                    [Tuple[PipelineBaseAst, StatementBlockAst]]::new(
                        $null,
                        $this.Ast.ElseClause),
                    [TokenKind]::Else)
            }
        }
    }
}

class HashtableAstItem : AstContainer {
    HashtableAstItem([HashtableAst] $ast) : base($ast) { }

    [object[]] GetChildItemImpl() {
        return $this.Ast.KeyValuePairs.ForEach{
            [HashtableKeyValuePairItem]::new($PSItem)
        }
    }
}

# The next two classes aren't based on an actual AST, they are AST pairs
# stored in a tuple
class IfStatementClauseItem : AstContainer {
    hidden [Tuple[PipelineBaseAst, StatementBlockAst]] $Clause;

    [TokenKind] $ClauseKind;

    IfStatementClauseItem(
        [Tuple[PipelineBaseAst, StatementBlockAst]] $clause,
        [TokenKind] $clauseKind)
        : base($null, $clauseKind)
    {
        $this.Clause = $clause
        $this.ClauseKind = $clauseKind
        $this.Extent = $clause.Item1.Extent, $clause.Item2.Extent | Join-ScriptExtent
    }

    [object[]] GetChildItemImpl() {
        return $this.Clause.Item1, $this.Clause.Item2
    }
}

class HashtableKeyValuePairItem : AstContainer {
    hidden [Tuple[ExpressionAst, StatementAst]] $KeyValuePair;

    HashtableKeyValuePairItem([Tuple[ExpressionAst, StatementAst]] $keyValuePair)
        : base($null, $keyValuePair.Item1.ToString())
    {
        $this.KeyValuePair = $keyValuePair
        $this.Extent = $keyValuePair.Item1.Extent, $keyValuePair.Item2.Extent | Join-ScriptExtent
    }

    [object[]] GetChildItemImpl() {
        return $this.KeyValuePair.Item1, $this.KeyValuePair.Item2
    }
}

class AstLeaf : SHiPSLeaf {
    [Ast] $Ast;
    [IScriptExtent] $Extent;

    AstLeaf([Ast] $ast) : base($ast.ForEach('GetType').Name) {
        $this.Ast = $ast
        $this.Extent = $ast.Extent
    }

    AstLeaf ([Ast] $ast, [string] $name) : base($name) {
        $this.Ast = $ast
        $this.Extent = $ast.Extent
    }

    [string] ToString() {
        return $this.Ast.ToString()
    }
}

class TypeConstraintAstItem : AstLeaf {
    [ITypeName] $TypeName;

    TypeConstraintAstItem([TypeConstraintAst] $ast) : base($ast, $ast.TypeName.Name) {
        $this.TypeName = $ast.TypeName
    }
}

class ConstantExpressionAstItem : AstLeaf {
    [type] $StaticType;
    [object] $Value;

    ConstantExpressionAstItem([ConstantExpressionAst] $ast) : base($ast) {
        $this.StaticType = $ast.StaticType
        $this.Value = $ast.Value
    }
}

class StringConstantExpressionAstItem : ConstantExpressionAstItem {
    [string] $Value;
    [StringConstantType] $StringConstantType;

    StringConstantExpressionAstItem([StringConstantExpressionAst] $ast) : base($ast) {
        $this.StringConstantType = $ast.StringConstantType
    }
}

class CommandParameterAstItem : AstLeaf {
    CommandParameterAstItem([CommandParameterAst] $ast) : base($ast, $ast.ParameterName) { }
}

class VariableExpressionAstItem : AstLeaf {
    [bool] $Splatted;
    [type] $StaticType;
    [VariablePath] $VariablePath;

    VariableExpressionAstItem([VariableExpressionAst] $ast)
        : base($ast, $ast.VariablePath.UserPath)
    {
        $this.Splatted = $ast.Splatted
        $this.StaticType = $ast.StaticType
        $this.VariablePath = $ast.VariablePath
    }
}

function New-EditorAstPSDrive {
    <#
    .EXTERNALHELP EditorAstProvider-help.xml
    #>
    [CmdletBinding()]
    param()
    end {
        $updateTypeDataSplat = @{
            MemberType = 'CodeProperty'
            MemberName = 'AstType'
            Value      = ([AstItemCodeMethods].GetMethod('AstTypeCodeProperty'))
            Force      = $true
        }

        Update-TypeData @updateTypeDataSplat -TypeName AstContainerBase
        Update-TypeData @updateTypeDataSplat -TypeName AstLeaf

        $newPSDriveSplat = @{
            Root       = 'EditorAstProvider#CurrentFileAst'
            PSProvider = 'SHiPS'
            Name       = 'CurrentFile'
            Scope      = 'Global'
        }

        New-PSDrive @newPSDriveSplat
    }
}

Export-ModuleMember -Function New-EditorAstPSDrive
