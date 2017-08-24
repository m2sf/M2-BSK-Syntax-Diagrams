#!/usr/bin/wish
#
# Syntax diagram generator for Modula-2 BSK, status Nov 15, 2016
#
# This script is derived from the SQLite project's bubble-generator script.
# It is quite possibly the only such tool that can wrap-around diagrams so
# that they do not go off-page when inserting them into an ordinary A4  or
# US letter document. Thanks to the folks at the SQLite project for making
# their script available to the public.
#
# The present version of the script was cleaned up,  enhanced,  documented
# and modified by B.Kowarsch to become accessible to those unfamiliar with
# TCL/TK, and in particular to generate syntax diagrams for Modula-2 (R10).
#
# Ideally the design would have been changed such that the script can read
# grammars from a text file in EBNF notation.  Ideally,  this script would
# have been rewritten in a more readable language,  Modula-2 for instance.
# Due to time constraints,  these tasks had to be left for some other time
# or for somebody else to do.  In the meantime  the documentation embedded
# herein should suffice  even for those unfamiliar with TCL  to modify the
# script to generate diagrams for their own grammars.
#
# THIS SOFTWARE COMES WITHOUT ANY WARRANTY OF ANY KIND. USE IS STRICTLY AT
# THE RISK OF THE USER.  PERSONS WHO HAVE A  LEGAL RIGHT TO SUE AUTHORS OF
# NO-WARRANTY-FREE-OF-CHARGE OPEN SOURCE SOFTWARE  ARE  SPECIFICALLY *NOT*
# GIVEN ANY PERMISSION TO USE THIS SOFTWARE.  THE BOTTOM LINE IS : YOU MAY
# USE THIS SOFTWARE WITHOUT PERMISSION ANYWAY,  BUT YOU  *CANNOT*  SUE THE
# AUTHORS FOR DAMAGES  BECAUSE  IF YOUR GOVERNMENT  GRANTS YOU SUCH RIGHTS
# THEN YOU DID  *NOT*  HAVE PERMISSION TO USE THIS SOFTWARE TO BEGIN WITH.
# THUS, NO MATTER WHAT THE CIRCUMSTANCES,  THE RISK IS ALWAYS YOURS ALONE.


#
# Top-level displays
#
toplevel .bb
canvas .c -bg white
pack .c -side top -fill both -expand 1
wm withdraw .

#  
# ===========================================================================
# D O C U M E N T A T I O N
# ===========================================================================
#
# The grammar is encoded as a nested TCL list structure of the general form:
#
#   { production1 { ... } production2 { ... } ... }
#
# Production rules can be translated from (ANTLR) EBNF to TCL list items as
# follows:
#
# Simple term
#
#   production : term ;
#   => production { line term }
#
# Sequence and group
#
#   production : term1 term2 ;
#   => production { line term1 term2 }
#
# Alternative
#
#   production : term1 | term2 ;
#   => production { or term1 term2 }
#
# Optional term
#
#   production : term? ;
#   => production { opt term }
#   => production { optx term }
#
#  opt renders the bypass line in the main path
#  optx renders the term in the main path
#
# Terms that occur one or more times
#
#   production : term+ ;
#   => production { loop { line term } {} }
#
# Terms that occur zero or more times
#
#   production : term* ;
#   => production { loop {} { nil term } }
#
# Causing diagrams to wrap-around
#
#   production : term1 /* wrap here */ term2 /* wrap here */ term3 ;
#   => production { stack {line term1} {line term2} {line term3} }
#
# Rendering of terminals, non-terminals and tokens
#
#   Symbols are rendered according to their category:
#   (1) reserved words, names in all uppercase letters
#   (2) reserved identifiers, names in all uppercase letters preceded by /
#   (3) other terminals, mixed case names with a leading uppercase letter
#   (4) non-terminals, mixed case names with a leading lowercase letter
#   (5) single letter tokens, a single letter or a range eg. a..z / A..Z
#   (6) special symbol tokens, any other characters or character sequences
#
# Special names for tokens that TCL cannot handle verbatim
#
#   BACKSLASH is rendered as \
#   SINGLE_QUOTE is rendered as '
#   DOUBLE_QUOTE is rendered as "
#   LEFT_BRACE is rendered as {
#   RIGHT_BRACE is rendered as }
#
# Rendering parameters
#
#   RES_WORD_FONT - font/size/style used to render reserved words
#   RES_IDENT_FONT - font/size/style used to render reserved identifiers
#   TERM_FONT - font/size/style used to render any other terminals
#   NON_TERM_FONT - font/size/style used to render non-terminals
#   TOKEN_FONT - font/size/style used to render tokens
#   RADIUS - turn radius for arcs
#   HSEP - horizontal separation
#   VSEP - vertical separation
#   LWIDTH -line width
#
# Pre-requisites
#
#   TCL and TK need to be installed
#
# Running the script
#
#   the most fool-proof method to run this script is to call the wish shell
#   with the name of the script as an argument:
#
#   $ wish modula2_syntax_diagrams.tcl
#
#   in the window that appears, click on the top button "Draw All Diagrams"
#
#   Diagrams will be written into postscript files in the working directory
#  
# ===========================================================================
#

# ===========================================================================
# Modula-2 grammar
# ===========================================================================
#  To reuse this diagram generator for other languages, replace the following
#  section with a definition of the grammar of the target language.
#
#  Do NOT add comments or blank lines within a production rule's definition!
#

# ---------------------------------------------------------------------------
# Non-Terminal Symbols
# ---------------------------------------------------------------------------
#
set non_terminals {}

# (1) Compilation Unit
lappend non_terminals compilationUnit {
  or
    {line definitionModule}
    {line implOrPrgmModule}
}


# ------------------------
# Definition Module Syntax
# ------------------------

# (2) Definition Module
lappend non_terminals definitionModule {
  stack
    {line DEFINITION MODULE moduleIdent ;}
    {line {loop nil import} {loop nil definition} END moduleIdent .}
}

# (2.1) Module Identifier
lappend non_terminals moduleIdent {
  line StdIdent
}

# (3) Import
lappend non_terminals import {
  line IMPORT {loop libIdent ,} ;
}

# (3.1) Module Identifier
lappend non_terminals libIdent {
  line StdIdent
}

# (4) omitted

# (5) Identifier
lappend non_terminals ident {
  or StdIdent ForeignIdent
}

# (5.1) Qualified Identifier
lappend non_terminals qualident {
  loop ident .
}

# (5.2) Identifier List
lappend non_terminals identList {
  loop ident ,
}

# (6) Definition
lappend non_terminals definition {
  line {
    or
      {line CONST {loop {line constDefinition ;} nil} }
      {line TYPE {loop {line typeDefinition ;} nil} }
      {line VAR {loop {line identList : typeIdent ;} nil} }
      {line procedureHeader ;}
      {line toDoList ;}
  }
}

# (6.1) Type Identifier
lappend non_terminals typeIdent {
  line qualident
}

# (7) Constant Definition
lappend non_terminals constDefinition {
  line ident = constExpression
}

# (7.1) Constant Expression
lappend non_terminals constExpression {
  line expression
}

# (8) Type Definition
lappend non_terminals typeDefinition {
  line ident = {or OPAQUE type}
}

# (10) Type
lappend non_terminals type {
  line {
    or
      {line aliasType}
      {line derivedType}
      {line subrangeType}
      {line enumType}
      {line setType}
      {line arrayType}
      {line recordType}
      {line pointerType}
      {line procedureType}
  }
}

# (10.1) Alias Type
lappend non_terminals aliasType {
  line ALIAS OF typeIdent
}

# (10.2) Derived Type
lappend non_terminals derivedType {
  line typeIdent
}

# (11) Subrange Type
lappend non_terminals subrangeType {
  line range OF countableType
}

# (11.1) Range Expression
lappend non_terminals range {
  line [ lowerBound .. upperBound ]
}

# (11.2) Lower Bound
lappend non_terminals lowerBound {
  line constExpression
}

# (11.3) Upper Bound
lappend non_terminals upperBound {
  line constExpression
}

# (11.4) Countable Type
lappend non_terminals countableType {
  line typeIdent
}

# (12) Enumeration Type
lappend non_terminals enumType {
  line ( {optx + enumTypeToExtend ,} identList )
}

# (12.1) Enumeration Type To Extend
lappend non_terminals enumTypeToExtend {
  line enumTypeIdent
}

# (12.2) Enumeration Type Identifier
lappend non_terminals enumTypeIdent {
  line typeIdent
}

# (13) Set Type
lappend non_terminals setType {
  line SET OF enumTypeIdent
}

# (14) Array Type
lappend non_terminals arrayType {
  line ARRAY valueCount OF typeIdent
}

# (14.1) Value Count
lappend non_terminals valueCount {
  line constExpression
}

# (15) Record Type
lappend non_terminals recordType {
  line RECORD {optx ( recTypeToExtend )} {loop fieldList ;} END
}

# (15.1) Record Type To Extend
lappend non_terminals recTypeToExtend {
  or typeIdent /NIL
}

# (15.2) Field List
lappend non_terminals fieldList {
  line varOrFieldDeclaration
}

# (16) Pointer Type
lappend non_terminals pointerType {
  line POINTER TO typeIdent
}

# (17) omitted

# (18) Procedure Type
lappend non_terminals procedureType {
  line PROCEDURE {optx ( {loop formalType ,} )} {optx : returnedType}
}

# (18.1) Formal Type
lappend non_terminals formalType {
  line {or CONST VAR nil} nonAttrFormalType
}

# (18.2) Non-Attributed Formal Type
lappend non_terminals nonAttrFormalType {
  or simpleFormalType castingFormalType variadicFormalType
}

# (18.3) Returned Type
lappend non_terminals returnedType {
  line typeIdent
}

# (19) Simple Formal Type
lappend non_terminals simpleFormalType {
  line {optx ARRAY OF} typeIdent
}

# (20) Casting Formal Type
lappend non_terminals castingFormalType {
  line /CAST {or /OCTETSEQ /ADDRESS}
}

# (22) Variadic Formal Type
lappend non_terminals variadicFormalType {
  line ARGLIST OF simpleFormalType
}

# (24) Procedure Header
lappend non_terminals procedureHeader {
  line PROCEDURE procedureSignature
}

# (25) Procedure Signature
lappend non_terminals procedureSignature {
  line ident {optx ( {loop formalParams ;} )} {optx : returnedType}
}

# (26) Formal Parameters
lappend non_terminals formalParams {
  line {or CONST VAR nil} identList : nonAttrFormalType
}


# ----------------------------------------
# Implementation and Program Module Syntax
# ----------------------------------------

# (30) Implementation or Program Module
lappend non_terminals implOrPrgmModule {
  stack
    {line {optx IMPLEMENTATION} MODULE moduleIdent ;}
    {line {loop nil privateImport} block moduleIdent .}
}

# (31) Private Import
lappend non_terminals privateImport {
  line import
}

# (32) Block
lappend non_terminals block {
  line {loop nil {nil declaration nil}}
  {optx BEGIN statementSequence} END
}

# (33) Declaration
lappend non_terminals declaration {
  line {
    or
      {line ALIAS {loop {line aliasDeclaration ;} nil}}
      {line CONST {loop {line ident = constExpression ;} nil}}
      {line TYPE {loop {line typeDeclaration ;} nil}}
      {line VAR {loop {line varOrFieldDeclaration ;} nil}}
      {line procedureHeader ; block ident ;}
      {line toDoList ;}
  }
}

# (33.1) Alias Declaration
lappend non_terminals aliasDeclaration {
  or
    namedAliasDecl
    wildcardAliasDecl
}

# (33.2) Named Alias Declaration
lappend non_terminals namedAliasDecl {
  line aliasName {
    or
      {line {loop {line , aliasName} nil} = qualifiedWildcard}
      {line = qualifiedName}
    }
}

# (33.3) Alias Name
lappend non_terminals aliasName {
  line ident
}

# (33.4) Qualified Name
lappend non_terminals qualifiedName {
  line qualident
}

# (33.5) Qualified Wildcard
lappend non_terminals qualifiedWildcard {
  line qualident .*
}

# (33.6) Wildcard Alias Declaration
lappend non_terminals wildcardAliasDecl {
  line * = qualifiedWildcard
}

# (34) Type Declaration
lappend non_terminals typeDeclaration {
  line ident = {or indeterminateType type}
}

# (34.1) Indeterminate Type
lappend non_terminals indeterminateType {
  line IN RECORD {optx {loop {line fieldList ;}}} indeterminateField END
}

# (34.2) Indeterminate Field Declaration
lappend non_terminals indeterminateField {
  line + ident : ARRAY OF typeIdent
}

# (35) Variable or Field Declaration
lappend non_terminals varOrFieldDeclaration {
  line identList : {or typeIdent anonType}
}

# (35.1) Anonymous Type
lappend non_terminals anonType {
  or
    {line ARRAY valueCount OF typeIdent}
    subrangeType
    procedureType
}

# (36) Statement Sequence
lappend non_terminals statementSequence {
  loop statement ;
}

# (37) Statement
lappend non_terminals statement {
  line {
    or
      emptyStatement
      memMgtOperation
      updateOrProcCall
      returnStatement
      copyStatement
      readStatement
      writeStatement
      ifStatement
      caseStatement
      loopStatement
      whileStatement
      repeatStatement
      forStatement
      EXIT
  }
}

# (37.1) Empty Statement
lappend non_terminals emptyStatement {
  line toDoList
}

# (38) Memory Management Operation
lappend non_terminals memMgtOperation {
  or
    {line NEW designator {optx OF initSize}}
    {line RELEASE designator}
}

# (38.1) Initial Size
lappend non_terminals initSize {
  line expression
}

# (39) Update Or Procedure Call
lappend non_terminals updateOrProcCall {
  line designator {
    or
      {line incOrDecSuffix}
      {line := expression}
      {line ( expressionList )}
      nil
    }
}

# (39.1) Increment Or Decrement Suffix
lappend non_terminals incOrDecSuffix {
  or
    {line ++}
    {line --}
}

# (40) Return Statement
lappend non_terminals returnStatement {
  line RETURN {optx expression}
}

# (41) COPY Statement
lappend non_terminals copyStatement {
  line COPY designator := expression
}

# (42) READ Statement
lappend non_terminals readStatement {
  line READ {optx @ chan :}
  {optx NEW} {loop designator ,}
}

# (42.1) Channel
lappend non_terminals chan {
  line designator
}

# (43) WRITE Statement
lappend non_terminals writeStatement {
  line WRITE {optx @ chan :}
  {loop outputArgs ,}
}

# 43.1) Output Arguments
lappend non_terminals outputArgs {
  or formattedArgs unformattedArgs
}

# (43.2) Formatted Output Arguments
lappend non_terminals formattedArgs {
  line [ fmtStr , unformattedArgs ]
}

# (43.3) Format String
lappend non_terminals fmtStr {
  line expression
}

# (43.4) Unformatted Arguments
lappend non_terminals unformattedArgs {
  line expressionList
}

# (44) IF Statement
lappend non_terminals ifStatement {
  stack
    {line IF boolExpression THEN statementSequence}
    {optx {loop {line ELSIF boolExpression THEN statementSequence} nil}}
    {line {optx ELSE statementSequence} END}
}

# (44.1) Boolean Expression
lappend non_terminals boolExpression {
  line expression
}

# (45) CASE Statement
lappend non_terminals caseStatement {
  line CASE expression OF
    {loop {line | case} nil} {optx ELSE statementSequence} END
}

# (45) CASE Statement 2
lappend non_terminals caseStatement2 {
  stack
    {line CASE expression OF {loop {line | case} nil}}
    {line {optx ELSE statementSequence} END}
}

# (45.1) Case
lappend non_terminals case {
  line {loop caseLabels ,} : statementSequence
}

# (45.2) Case Labels
lappend non_terminals caseLabels {
  line constExpression {optx .. constExpression}
}

# (46) LOOP Statement
lappend non_terminals loopStatement {
  line LOOP statementSequence END
}

# (47) WHILE Statement
lappend non_terminals whileStatement {
  line WHILE boolExpression DO statementSequence END
}

# (47) WHILE Statement 2
lappend non_terminals whileStatement2 {
  stack
    {line WHILE boolExpression DO statementSequence}
    {line {optx ELSE statementSequence} END}
}

# (48) REPEAT Statement
lappend non_terminals repeatStatement {
  line REPEAT statementSequence UNTIL boolExpression
}

# (49) FOR Statement
lappend non_terminals forStatement {
  line FOR forLoopVariants IN iterableExpr DO statementSequence END
}

# (49) FOR Statement 2
lappend non_terminals forStatement2 {
  stack
    {line FOR forLoopVariants IN iterableExpr}
    {line DO statementSequence END}
}

# (49.1) FOR Loop Variants
lappend non_terminals forLoopVariants {
  line indexOrSoleValue {optx ascOrDesc} {optx , value}
}

# (49.2) Index, Value
lappend non_terminals indexOrSoleValue {
  line ident
}

# (49.3) Ascender Or Descender
lappend non_terminals ascOrDesc {
  line incOrDecSuffix
}

# (49.4) Iterable Expression
lappend non_terminals iterableExpr {
  or
    {line ordinalRange OF ordinalType}
    designator
}

# (49.5) Ordinal Range
lappend non_terminals ordinalRange {
  line [ firstValue .. lastValue ]
}

# (49.6) First Value
lappend non_terminals firstValue {
  line expression
}

# (49.7) Last Value
lappend non_terminals lastValue {
  line expression
}

# (49.8) Ordinal Type
lappend non_terminals ordinalType {
  line typeIdent
}

# (50) Designator
lappend non_terminals designator {
  line ident {optx designatorTail}
}

# (50.1) Designator Tail CORRECTED
lappend non_terminals designatorTail {
  or
    {line {or deref fieldSelector} {optx designatorTail}}
    subscriptOrSlice
}

# (50.2) Subscript Or Slice
lappend non_terminals subscriptOrSlice {
  line [ expression {
    or
      {line ] {optx designatorTail}}
      {line .. {optx expression} ]}
    }
}

# (50.3) Deref
lappend non_terminals deref {
  line ^
}

# (50.4) Field Selector
lappend non_terminals fieldSelector {
  line . ident
}

# (50.2) Expression Or Slice
lappend non_terminals exprOrSlice {
  line expression {optx .. {optx expression}}
}

# (51) Expression List
lappend non_terminals expressionList {
  loop expression ,
}

# (52) Expression
lappend non_terminals expression {
  line simpleExpression {optx operL1 simpleExpression}
}

# (52.1) Level-1 Operator
lappend non_terminals operL1 {
  or
    = # < <= > >= == IN
}

# (53) Simple Expression
lappend non_terminals simpleExpression {
  or
    {loop term operL2}
    {line - simpleFactor}
}

# (53.1) Level-2 Operator
lappend non_terminals operL2 {
  or + - OR concatOp setDiffOp
}

# (53.2) Concatenation Operator
lappend non_terminals concatOp {
  line &
}

# (53.3) Set Difference Operator
lappend non_terminals setDiffOp {
  line BACKSLASH
}

# (54) Term
lappend non_terminals term {
  loop simpleTerm operL3
}

# (54.1) Level-3 Operator
lappend non_terminals operL3 {
  or * / DIV MOD AND
}

# (55) Simple Term
lappend non_terminals simpleTerm {
  line {optx NOT} factor
}

# (56) Factor
lappend non_terminals factor {
  line simpleFactor {optx typeConvOp typeIdent}
}

# (56.1) Type Conversion Operator
lappend non_terminals typeConvOp {
  line ::
}

# (57) Simple Factor
lappend non_terminals simpleFactor {
  line {
    or
      NumberLiteral
      StringLiteral
      structuredValue
      designatorOrFuncCall
      {line ( expression )}
    }
}

# (57.1) Designator Or Function Call
lappend non_terminals designatorOrFuncCall {
  line designator {optx ( {optx expressionList} )}
}

# (57.2) Structured Value
lappend non_terminals structuredValue {
  line LBRACE {loop valueComponent ,} RBRACE
}

# (57.3) Value Component
lappend non_terminals valueComponent {
  or
    {line constExpression {optx .. constExpression}}
    {line runtimeExpression}
}

# (57.4) Runtime Expression
lappend non_terminals runtimeExpression {
  line expression
}


# (58) TO DO List
lappend non_terminals toDoList {
  line TO DO {
    or
      {line {optx trackingRef} {loop taskToDo ;} END}
      nil
    }
}

# (58.1) Tracking Reference
lappend non_terminals trackingRef {
  line ( issueId , weight )
}

# 58.2) IssueId
lappend non_terminals issueId {
  line wholeNumber
}

# (58.3) Whole Number
lappend non_terminals wholeNumber {
  line NumberLiteral 
}

# (58.4) Task To Do
lappend non_terminals taskToDo {
  line description {optx , estimatedHours}
}

# (58.5) Description
lappend non_terminals description {
  line StringLiteral
}

# (58.6) Weight, Estimated Hours
lappend non_terminals estimatedHours {
  line constExpression
}


# ---------------------------------------------------------------------------
# Terminal Symbols
# ---------------------------------------------------------------------------
#
set terminals {}

# ------------------
# (1) Reserved Words
# ------------------
set res_words {}

# (1.1) ALIAS
lappend res_words ALIAS {
  line ALIAS
}

# (1.2) AND
lappend res_words AND {
  line AND
}

# (1.3) ARGLIST
lappend res_words ARGLIST {
  line ARGLIST
}

# (1.4) ARRAY
lappend res_words ARRAY {
  line ARRAY
}

# (1.5) BARE
lappend res_words BARE {
  line BARE
}

# (1.6) BEGIN
lappend res_words BEGIN {
  line BEGIN
}

# (1.9) CASE
lappend res_words CASE {
  line CASE
}

# (1.10) CONST
lappend res_words CONST {
  line CONST
}

# (1.12) DEFINITION
lappend res_words DEFINITION {
  line DEFINITION
}

# (1.13) DIV
lappend res_words DIV {
  line DIV
}

# (1.14) DO
lappend res_words DO {
  line DO
}

# (1.15) ELSE
lappend res_words ELSE {
  line ELSE
}

# (1.16) ELSIF
lappend res_words ELSIF {
  line ELSIF
}

# (1.17) END
lappend res_words END {
  line END
}

# (1.18) EXIT
lappend res_words EXIT {
  line EXIT
}

# (1.19) FOR
lappend res_words FOR {
  line FOR
}

# (1.22) IF
lappend res_words IF {
  line IF
}

# (1.23) IMPLEMENTATION
lappend res_words IMPLEMENTATION {
  line IMPLEMENTATION
}

# (1.24) IMPORT
lappend res_words IMPORT {
  line IMPORT
}

# (1.25) IN
lappend res_words IN {
  line IN
}

# (1.26) LOOP
lappend res_words LOOP {
  line LOOP
}

# (1.27) MOD
lappend res_words MOD {
  line MOD
}

# (1.28) MODULE
lappend res_words MODULE {
  line MODULE
}

# (1.29) NEW
lappend res_words NEW {
  line NEW
}

# (1.31) NOT
lappend res_words NOT {
  line NOT
}

# (1.32) OF
lappend res_words OF {
  line OF
}

# (1.33) OPAQUE
lappend res_words OPAQUE {
  line OPAQUE
}

# (1.34) OR
lappend res_words OR {
  line OR
}

# (1.35) POINTER
lappend res_words POINTER {
  line POINTER
}

# (1.36) PROCEDURE
lappend res_words PROCEDURE {
  line PROCEDURE
}

# (1.37) RECORD
lappend res_words RECORD {
  line RECORD
}

# (1.39) RELEASE
lappend res_words RELEASE {
  line RELEASE
}

# (1.40) REPEAT
lappend res_words REPEAT {
  line REPEAT
}

# (1.42) RETURN
lappend res_words RETURN {
  line RETURN
}

# (1.43) SET
lappend res_words SET {
  line SET
}

# (1.44) THEN
lappend res_words THEN {
  line THEN
}

# (1.45) TO
lappend res_words TO {
  line TO
}

# (1.46) TYPE
lappend res_words TYPE {
  line TYPE
}

# (1.47) UNTIL
lappend res_words UNTIL {
  line UNTIL
}

# (1.48) VAR
lappend res_words VAR {
  line VAR
}

# (1.49) WHILE
lappend res_words WHILE {
  line WHILE
}


# ------------------------
# (2) Dual-Use Identifiers
# ------------------------
set res_idents {}

# (2.2) ADDRESS
lappend res_idents ADDRESS {
  line /ADDRESS
}

# (2.4) CAST
lappend res_idents CAST {
  line /CAST
}

# (2.10) OCTET
lappend res_idents /OCTET {
  line /OCTET
}

# (2.28) UNSAFE
lappend res_idents UNSAFE {
  line /UNSAFE
}


# -------------------
# (3) Special Symbols
# -------------------
set res_symbols {}

# (3.1) Dot
lappend res_symbols Dot {
  line .
}

# (3.2) Comma
lappend res_symbols Comma {
  line ,
}

# (3.3) Colon
lappend res_symbols Colon {
  line :
}

# (3.4) Semicolon
lappend res_symbols Semicolon {
  line ;
}

# (3.5) Vertical Bar
lappend res_symbols VerticalBar {
  line |
}

# (3.6) Caret
lappend res_symbols Caret {
  line ^
}

# (3.7) Double Dot
lappend res_symbols DoubleDot {
  line ..
}

# (3.8) Assign
lappend res_symbols Assign {
  line :=
}

# (3.9) Double Plus
lappend res_symbols DoublePlus {
  line ++
}

# (3.10) Double Minus
lappend res_symbols DoubleMinus {
  line --
}

# (3.11) Double Colon
lappend res_symbols DoubleColon {
  line ::
}

# (3.12) Plus
lappend res_symbols Plus {
  line +
}

# (3.13) Minus
lappend res_symbols Minus {
  line -
}

# (3.14) Asterisk
lappend res_symbols Asterisk {
  line *
}

# (3.15) Slash
lappend res_symbols Slash {
  line /
}

# (3.16) Backslash
lappend res_symbols Backslash {
  line BACKSLASH
}

# (3.17) Equal
lappend res_symbols Equal {
  line =
}

# (3.18) Not Equal
lappend res_symbols NotEqual {
  line #
}

# (3.19) Greater Than
lappend res_symbols GreaterThan {
  line >
}

# (3.20) Greater Or Equal
lappend res_symbols GreaterOrEqual {
  line >=
}

# (3.21) Less Than
lappend res_symbols LessThan {
  line <
}

# (3.22) Less Or Equal
lappend res_symbols LessOrEqual {
  line <=
}

# (3.24) Ampersand
lappend res_symbols Ampersand {
  line &
}

# (3.29) Left Parenthesis
lappend res_symbols LeftParen {
  line (
}

# (3.30) Right Parenthesis
lappend res_symbols RightParen {
  line )
}

# (3.31) Left Bracket
lappend res_symbols LeftBracket {
  line [
}

# (3.32) Right Bracket
lappend res_symbols RightBracket {
  line ]
}

# (3.33) Left Brace
lappend res_symbols LeftBrace {
  line LBRACE
}

# (3.34) Right Brace
lappend res_symbols RightBrace {
  line RBRACE
}

# (3.36) Open Pragma
lappend res_symbols OpenPragma {
  line <*
}

# (3.37) Close Pragma
lappend res_symbols ClosePragma {
  line *>
}

# (3.38) Single Quote
lappend res_symbols SingleQuote {
  line SINGLE_QUOTE
}

# (3.39) Double Quote
lappend res_symbols DoubleQuote {
  line DOUBLE_QUOTE
}

# (3.42) Exclamation
lappend res_symbols Exclamation {
  line !
}

# (3.43) Open Comment
lappend res_symbols OpenComment {
  line (*
}

# (3.44) Close Comment
lappend res_symbols CloseComment {
  line *)
}


# -----------------------
# (4) Standard Identifier
# -----------------------

# (4) Standard Identifier
lappend terminals StdIdent {
  line Letter {loop nil LetterOrDigit}
}

# (4.1) Letter Or Digit
lappend terminals LetterOrDigit {
  or Letter Digit
}


# ----------------------
# (5) Foreign Identifier
# ----------------------

lappend terminals ForeignIdent {
  or
    {line $ {loop LetterOrDigit nil} {loop nil ForeignIdentTail}}
    {line StdIdent {loop ForeignIdentTail nil}}
}

# (4.1) Foreign Identifier Tail
lappend terminals ForeignIdentTail {
  line {or $ _} {loop LetterOrDigit nil}
}


# ------------------
# (6) Number Literal
# ------------------
lappend terminals NumberLiteral {
  or
    {line 0 {
      or
        RealNumberTail
        {line b Base2DigitSeq}
        {line x Base16DigitSeq}
        {line u Base16DigitSeq}
        nil
      }}
    {line 1..9 {optx DecimalNumberTail}}
}

# (6.1) Decimal Number Tail
lappend terminals DecimalNumberTail {
  or
   {line {optx SINGLE_QUOTE} DigitSeq {optx RealNumberTail}}
   RealNumberTail
}

# Digit Separator
# lappend terminals DigitSep {
#   line SINGLE_QUOTE
# }

# (6.2) Real Number Tail
lappend terminals RealNumberTail {
  line . DigitSeq {optx e {or + - nil} DigitSeq }
}

# (6.3) Digit Sequence
lappend terminals DigitSeq {
  loop DigitGroup SINGLE_QUOTE
}

# (6.3b) Digit Group
lappend terminals DigitGroup {
  loop Digit nil
}

# (6.4) Base-16 Digit Sequence
lappend terminals Base16DigitSeq {
  loop Base16DigitGroup SINGLE_QUOTE
}

# (6.4b) Base-16 Digit Group
lappend terminals Base16DigitGroup {
  loop Base16Digit nil
}

# (6.5) Base-2 Digit Sequence
lappend terminals Base2DigitSeq {
  loop Base2DigitGroup SINGLE_QUOTE
}

# (6.5b) Base-2 Digit Group
lappend terminals Base2DigitGroup {
  loop Base2Digit nil
}

# (6.6) Digit
lappend terminals Digit {
  or Base2Digit 2 3 4 5 6 7 8 9
}

# (6.7) Base-16 Digit
lappend terminals Base16Digit {
  or Digit A B C D E F
}

# (6.8) Base-2 Digit
lappend terminals Base2Digit {
  or 0 1
}

# ------------------
# (7) String Literal
# ------------------
lappend terminals StringLiteral {
  or SingleQuotedString DoubleQuotedString
}

# (7.1) Single Quoted String
lappend terminals SingleQuotedString {
  line SINGLE_QUOTE
    {optx {loop {or QuotableCharacter DOUBLE_QUOTE} nil}}
  SINGLE_QUOTE
}

# (7.2) Double Quoted String
lappend terminals DoubleQuotedString {
  line DOUBLE_QUOTE
    {optx {loop {or QuotableCharacter SINGLE_QUOTE} nil}}
  DOUBLE_QUOTE
}

# (7.3) Quotable Character
lappend terminals QuotableCharacter {
  or Digit Letter Space NonAlphaNumQuotable EscapedCharacter
}

# (7.4) Letter
lappend terminals Letter {
  or A..Z a..z 
}

# (7.5) Space
# CONST Space = CHR(32);

# (7.6a) Non-Alphanumeric Quotable Character
lappend terminals NonAlphaNumQuotable1 {
  or ! # $ % & ( ) * + ,
}

# (7.6b) Non-Alphanumeric Quotable Character
lappend terminals NonAlphaNumQuotable2 {
  or - . / : ; < = > ? @
}

# (7.6c) Non-Alphanumeric Quotable Character
lappend terminals NonAlphaNumQuotable3 {
  or [ ] ^ _ ` LBRACE | RBRACE ~
}

# (7.7) Escaped Character
lappend terminals EscapedCharacter {
  line BACKSLASH {or n t BACKSLASH}
}


# ---------------------------------------------------------------------------
# Ignore Symbols
# ---------------------------------------------------------------------------
#
set ignore_symbols {}

# (1) Whitespace
lappend ignore_symbols Whitespace {
  or Space ASCII_TAB
}

# (1.1) ASCII_TAB
# CONST ASCII_TAB = CHR(9);

# (2) Line Comment
lappend ignore_symbols LineComment {
  line ! {optx {loop CommentCharacter nil}} EndOfLine
}

# (3) Block Comment
lappend ignore_symbols BlockComment {
  line (* {optx {loop {or CommentCharacter BlockComment EndOfLine} nil}} *)
}

# (3.1) Comment Character
lappend ignore_symbols CommentCharacter {
  or Digit Letter Whitespace NonAlphaNumQuotable
  BACKSLASH SINGLE_QUOTE DOUBLE_QUOTE
}

# (5) End-Of-Line Marker
lappend ignore_symbols EndOfLine {
  or
    {line ASCII_LF}
    {line ASCII_CR {optx ASCII_LF}}
}

# (5.1) ASCII_LF
# CONST ASCII_LF = CHR(10);

# (5.2) ASCII_CR
# CONST ASCII_CR = CHR(13);

# (6) UTF8 BOM
# CONST UTF8_BOM = { 0uEF, 0uBB, 0uBF };


# ---------------------------------------------------------------------------
# Debugging Aid -- Not part of the language specification
# ---------------------------------------------------------------------------
#

# (4) Disabled Code Section
lappend ignore_symbols DisabledCodeSection {
  line
    StartOfLine ?<
    {loop {or AnyPrintable Whitespace EndOfLine} nil}
    EndOfLine >?
}

# (4.1) Start Of Line
# not a symbol

# (4.2) Any Printable Character
lappend ignore_symbols AnyPrintable {
  line 0u20..0u7E
}

# ---------------------------------------------------------------------------
# Pragma Grammar (optional in M2 BSK)
# ---------------------------------------------------------------------------
#
set pragmas {}

# (1) Pragma
lappend pragmas pragma {
  line <* pragmaBody *>
}

# (1.1) Pragma Body
lappend pragmas pragmaBody {
  or
    ffiPragma
    ffidentPragma
}

# (15) Body Of Foreign Function Interface Pragma
lappend pragmas ffiPragma {
  line FFI = {or `C `CLR `JVM }
}

# (16) Body Of Foreign Function Identifier Mapping Pragma
lappend pragmas ffidentPragma {
  line FFIDENT = StringLiteral
}


# ---------------------------------------------------------------------------
# Alias Diagrams
# ---------------------------------------------------------------------------
#
set aliases {}

# Alias For Identifier
lappend aliases AliasForIdent {
  line Ident
}

# Alias For Blueprint Identifier
lappend aliases AliasForBlueprintIdent {
  line blueprintIdent
}

# Alias For Qualified Identifier
lappend aliases AliasForQualident {
  line qualident
}

# Alias For Number
lappend aliases AliasForNumericLiteral {
  line NumericLiteral
}

# Alias For Whole Number
lappend aliases AliasForWholeNumber {
  line wholeNumber
}

# Alias For String
lappend aliases AliasForStringLiteral {
  line StringLiteral
}

# Alias For Constant Expression
lappend aliases AliasForConstExpr {
  line constExpression
}

# Alias For Expression
lappend aliases AliasForExpression {
  line expression
}

# Alias For Type Identifier
lappend aliases AliasForTypeIdent {
  line typeIdent
}


# ---------------------------------------------------------------------------
# Legend Diagrams
# ---------------------------------------------------------------------------
#
set legend {}

# EBNF -- Terminal #
lappend legend EBNF_terminal {
  line Terminal
}

# EBNF -- Non-Terminal #
lappend legend EBNF_non_terminal {
  line nonTerminal
}

# EBNF -- Literal #
lappend legend EBNF_literal_hash {
  line #
}

# EBNF -- Literal BAZ
lappend legend EBNF_literal_BAZ {
  line BAZ
}

# EBNF -- Sequence #
lappend legend EBNF_sequence {
  line bar baz
}

# EBNF -- Alternative #
lappend legend EBNF_alternative {
  or bar baz
}

# EBNF -- Grouping #
lappend legend EBNF_grouping {
  line bar {or baz bam}
}

# EBNF -- Option #
lappend legend EBNF_option {
  optx bar
}

# EBNF -- Kleene Star #
lappend legend EBNF_kleene_star {
  loop nil bar
}

# EBNF -- One Or More #
lappend legend EBNF_one_or_more {
  loop bar nil
}

# EBNF -- (bar baz)+ #
lappend legend EBNF_bar_baz_plus {
  loop {line bar baz} nil
}

# EBNF -- (bar baz) | (bar bam) #
lappend legend EBNF_bar_baz_or_bar_bam {
  line {or {line bar baz} {line bar bam}}
}

# EBNF -- bar (baz| bam) #
lappend legend EBNF_bar_or_baz_bam {
  line bar {or baz bam}
}

# EBNF -- bar (baz| bam) #
lappend legend EBNF_code_option {
  line {optx bar} baz
}

# EBNF -- bar (baz| bam) #
lappend legend EBNF_code_kleene_star {
  line {loop nil bar} baz
}

# EBNF -- bar (baz| bam) #
lappend legend EBNF_code_plus {
  line {loop bar nil} baz
}

# Legend -- Reserved Word
lappend legend legendReservedWord {
  line RESERVED
}

# Legend -- Terminal Symbol, Example 1
lappend legend legendTerminal1 {
  line #
}

# Legend -- Terminal Symbol, Example 2
lappend legend legendTerminal2 {
  line Terminal
}

# Legend -- Identifier
lappend legend legendIdentifier {
  line /IDENTIFIER
}

# Legend -- Non-Terminal Symbol
lappend legend legendNonTerminal {
  line nonTerminal
}

# end Modula-2 grammar


#  
# ===========================================================================
# C O D E   S T A R T S   H E R E
# ===========================================================================
#


# ---------------------------------------------------------------------------
# Draw the button box
# ---------------------------------------------------------------------------
#
set bn 0
set b .bb.b$bn
wm title .bb "Modula-2"

# Menu: All Diagrams
#
button $b -text "Draw All Diagrams" -command {draw_all_graphs}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Non-Terminals
#
incr bn
set b .bb.b$bn
button $b -text "Draw Non-Terminals" -command {draw_graphs $non_terminals}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Terminals
#
incr bn
set b .bb.b$bn
button $b -text "Draw Terminals" -command {draw_graphs $terminals}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Reserved Words
#
incr bn
set b .bb.b$bn
button $b -text "Draw Reserved Words" -command {draw_graphs $res_words}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Dual-Use Identifiers
#
incr bn
set b .bb.b$bn
button $b -text "Draw Dual-Use Identifiers" -command {draw_graphs $res_idents}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Special Symbols
#
incr bn
set b .bb.b$bn
button $b -text "Draw Special Symbols" -command {draw_graphs $res_symbols}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Pragmas
#
incr bn
set b .bb.b$bn
button $b -text "Draw Pragmas" -command {draw_graphs $pragmas}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Ignore Symbols
#
incr bn
set b .bb.b$bn
button $b -text "Draw Ignore Symbols" -command {draw_graphs $ignore_symbols}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Aliases
#
incr bn
set b .bb.b$bn
button $b -text "Draw Aliases" -command {draw_graphs $aliases}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Legend
#
incr bn
set b .bb.b$bn
button $b -text "Draw Legend" -command {draw_graphs $legend}
pack $b -side top -fill x -expand 0 -pady 0

# Menu: Quit
#
incr bn
set b .bb.b$bn
button $b -text "Quit" -command {exit}
pack $b -side top -fill x -expand 0 -pady {0 14}


# ---------------------------------------------------------------------------
# L a y o u t - P a r a m e t e r s
# ---------------------------------------------------------------------------
#
set RES_WORD_FONT {Helvetica 12 bold};           # reserved word font
set RES_IDENT_FONT {Helvetica 12 bold italic};   # reserved identifier font
set TERM_FONT {Helvetica 12 bold};               # font for other terminals
set NON_TERM_FONT {Helvetica 12};                # non-terminal font
set TOKEN_FONT {Monaco 12 bold};                 # special symbol token font
set STRING_FONT {Courier 12 bold};               # quoted string font
set RADIUS 9;                                    # default turn radius
set HSEP 15;                                     # horizontal separation
set VSEP 7;                                      # vertical separation
set LWIDTH 3;                                    # line width
set DPI 96;                                      # dots per inch for GIFs

set tagcnt 0; # tag counter - don't modify this


# ---------------------------------------------------------------------------
# Draw a right-hand turn around.  Approximately a ")"
# ---------------------------------------------------------------------------
#
proc draw_right_turnback {tag x y0 y1} {
  global RADIUS
  global LWIDTH
  if {$y0 + 2*$RADIUS < $y1} {
    set xr0 [expr {$x-$RADIUS}]
    set xr1 [expr {$x+$RADIUS}]
    .c create arc $xr0 $y0 $xr1 [expr {$y0+2*$RADIUS}] \
          -width $LWIDTH -start 90 -extent -90 -tags $tag -style arc
    set yr0 [expr {$y0+$RADIUS}]
    set yr1 [expr {$y1-$RADIUS}]
    if {abs($yr1-$yr0)>$RADIUS*2} {
      set half_y [expr {($yr1+$yr0)/2}]
      .c create line $xr1 $yr0 $xr1 $half_y -width $LWIDTH -tags $tag -arrow last
      .c create line $xr1 $half_y $xr1 $yr1 -width $LWIDTH -tags $tag
    } else {
      .c create line $xr1 $yr0 $xr1 $yr1 -width $LWIDTH -tags $tag
    }
    .c create arc $xr0 [expr {$y1-2*$RADIUS}] $xr1 $y1 \
          -width $LWIDTH -start 0 -extent -90 -tags $tag -style arc
  } else { 
    set r [expr {($y1-$y0)/2.0}]
    set x0 [expr {$x-$r}]
    set x1 [expr {$x+$r}]
    .c create arc $x0 $y0 $x1 $y1 \
          -width $LWIDTH -start 90 -extent -180 -tags $tag -style arc
  }
} ;# end draw_right_turnback


# ---------------------------------------------------------------------------
# Draw a left-hand turn around.  Approximatley a "("
# ---------------------------------------------------------------------------
#
proc draw_left_turnback {tag x y0 y1 dir} {
  global RADIUS
  global LWIDTH
  if {$y0 + 2*$RADIUS < $y1} {
    set xr0 [expr {$x-$RADIUS}]
    set xr1 [expr {$x+$RADIUS}]
    .c create arc $xr0 $y0 $xr1 [expr {$y0+2*$RADIUS}] \
          -width $LWIDTH -start 90 -extent 90 -tags $tag -style arc
    set yr0 [expr {$y0+$RADIUS}]
    set yr1 [expr {$y1-$RADIUS}]
    if {abs($yr1-$yr0)>$RADIUS*3} {
      set half_y [expr {($yr1+$yr0)/2}]
      if {$dir=="down"} {
        .c create line $xr0 $yr0 $xr0 $half_y -width $LWIDTH -tags $tag -arrow last
        .c create line $xr0 $half_y $xr0 $yr1 -width $LWIDTH -tags $tag
      } else {
        .c create line $xr0 $yr1 $xr0 $half_y -width $LWIDTH -tags $tag -arrow last
        .c create line $xr0 $half_y $xr0 $yr0 -width $LWIDTH -tags $tag
      }
    } else {
      .c create line $xr0 $yr0 $xr0 $yr1 -width $LWIDTH -tags $tag
    }
    # .c create line $xr0 $yr0 $xr0 $yr1 -width $LWIDTH -tags $tag
    .c create arc $xr0 [expr {$y1-2*$RADIUS}] $xr1 $y1 \
          -width $LWIDTH -start 180 -extent 90 -tags $tag -style arc
  } else { 
    set r [expr {($y1-$y0)/2.0}]
    set x0 [expr {$x-$r}]
    set x1 [expr {$x+$r}]
    .c create arc $x0 $y0 $x1 $y1 \
          -width $LWIDTH -start 90 -extent 180 -tags $tag -style arc
  }
} ;# end draw_left_turnback


# ---------------------------------------------------------------------------
# Draw a bubble containing $txt. 
# ---------------------------------------------------------------------------
#
proc draw_bubble {txt} {
  global LWIDTH
  global tagcnt
  incr tagcnt
  set tag x$tagcnt
  if {$txt=="nil"} {
    .c create line 0 0 1 0 -width $LWIDTH -tags $tag
    return [list $tag 1 0]
  } elseif {$txt=="bullet"} {
    .c create oval 0 -3 6 3 -width $LWIDTH -tags $tag
    return [list $tag 6 0]
  }
# special name replacements
  set isQuotedString 0
  if {$txt=="SPACE"} {
    set label "' '"
  } elseif {$txt=="BACKSLASH"} {
    set label "\\"
  } elseif {$txt=="SINGLE_QUOTE"} {
    set label "\'"
  } elseif {$txt=="DOUBLE_QUOTE"} {
    set label "\""
  } elseif {$txt=="LBRACE" || $txt=="LEFT_BRACE"} {
    set label "\{"
  } elseif {$txt=="RBRACE" || $txt=="RIGHT_BRACE"} {
    set label "\}"
  } else {
    set label $txt
  }
# initialise symbol flags
  set isReservedIdent 0
  set isNonTerminal 0
  set isTerminal 0
  set isToken 0
# determine type of symbol
  if {[regexp {^[A-Z][A-Z]+$} $label]} {
    # reserved word
    set isTerminal 1
    set isReservedWord 1
    set font $::RES_WORD_FONT
    set label " $label "
    set baseline [expr {$LWIDTH/2}]
  } elseif {[regexp {^/[A-Z][A-Z]+$} $label]} {
    set label [string range $label 1 end]
    # reserved identifier
    set isTerminal 1
    set isReservedIdent 1
    set font $::RES_IDENT_FONT
    set label " $label "
    set baseline [expr {$LWIDTH/2}]
  } elseif {[regexp {^[A-Z][a-z0-9][a-zA-Z0-9]*$} $label]} {
    # other terminal
    set isTerminal 1
    set font $::TERM_FONT
    set label " $label "
    set baseline [expr {$LWIDTH/2}]
  } elseif {[regexp {^[a-z][a-zA-Z0-9]+$} $label]} {
    # non-terminal
    set isNonTerminal 1
    set font $::NON_TERM_FONT
    set label "  $label  "
    set baseline 0
 } elseif {[regexp {^`[a-zA-Z0-9]+$} $label]} {
    # quoted string literal
    set label [string range $label 1 end]
    set isToken 1
    set font $::STRING_FONT
    set label " \"$label\" "
    set baseline [expr {$LWIDTH/2}]
 } elseif {[regexp {^[a-zA-Z]$} $label]} {
    # single letter token
    set isToken 1
    set font $::TOKEN_FONT
    set baseline [expr {$LWIDTH/2}]
 } elseif {[regexp {^[a-zA-Z0-9]\.\.[a-zA-Z0-9]$} $label]} {
    # letter or digit range
    set isToken 1
    set font $::TOKEN_FONT
    set baseline [expr {$LWIDTH/2}]
 } else {
    # anything else is a token
    set isToken 1
    set font $::TOKEN_FONT
    set baseline [expr {$LWIDTH/2}]
  }
  set id1 [.c create text 0 $baseline -anchor c -text $label -font $font -tags $tag]
# lassign [.c bbox $id1] x0 y0 x1 y1 # to do: replace all foreach with lassign
  foreach {x0 y0 x1 y1} [.c bbox $id1] break
# move parentheses, brackets, braces and underscore up by one pixel
  if {$label in {( ) [ ] \{ \} _ }} { .c move $id1 0 -1 }
# move the asterisk down by one pixel
  if {$label=="*"} { .c move $id1 0 1 }
# move label left by one pixel if font is italic
  set slantAttr [font actual $font -slant]
  if {$slantAttr eq "italic"} { .c move $id1 -1 0 }
  set h [expr {$y1-$y0+$LWIDTH}]
  set rad [expr {($h+1)/2}]
  if {$isNonTerminal} {
    set top [expr {$y0-$LWIDTH}]
    set btm [expr {$y1+$LWIDTH}]
    set left [expr {$x0-$LWIDTH}]
    set right [expr {$x1+$LWIDTH}]
    .c create rect $left $top $right $btm -width $LWIDTH -tags $tag
  } else {
    set top [expr {$y0-$LWIDTH}]
    set btm [expr {$y1+1}]
    set left [expr {$x0+$LWIDTH}]
    set right [expr {$x1-$LWIDTH}]
    if {$left>$right} {
      set left [expr {($x0+$x1)/2}]
      set right $left
    }
    .c create arc [expr {$left-$rad}] $top [expr {$left+$rad}] $btm \
         -width $LWIDTH -start 90 -extent 180 -style arc -tags $tag
    .c create arc [expr {$right-$rad}] $top [expr {$right+$rad}] $btm \
         -width $LWIDTH -start -90 -extent 180 -style arc -tags $tag
    if {$left<$right} {
      .c create line $left $top $right $top -width $LWIDTH -tags $tag
      .c create line $left $btm $right $btm -width $LWIDTH -tags $tag
    }
  }
  foreach {x0 y0 x1 y1} [.c bbox $tag] break
  set width [expr {$x1-$x0}]
  .c move $tag [expr {-$x0}] 0

  # Entry is always 0 0
  # Return:  TAG EXIT_X EXIT_Y
  #
  return [list $tag $width 0]
} ;# end draw_bubble


# ---------------------------------------------------------------------------
# Draw a sequence of terms from left to write.
# ---------------------------------------------------------------------------
# Each element of $lx describes a single term.
#
proc draw_line {lx} {
  global LWIDTH
  global tagcnt
  incr tagcnt
  set tag x$tagcnt

  set sep $::HSEP
  set exx 0
  set exy 0
  foreach term $lx {
    set m [draw_diagram $term]
    foreach {t texx texy} $m break
    if {$exx>0} {
      set xn [expr {$exx+$sep}]
      .c move $t $xn $exy
      .c create line [expr {$exx-1}] $exy $xn $exy \
         -tags $tag -width $LWIDTH -arrow last
      set exx [expr {$xn+$texx}]
    } else {
      set exx $texx
    }
    set exy $texy
    .c addtag $tag withtag $t
    .c dtag $t $t
  }
  if {$exx==0} {	
    set exx [expr {$sep*2}]
    .c create line 0 0 $sep 0 -width $LWIDTH -tags $tag -arrow last
    .c create line $sep 0 $exx 0 -width $LWIDTH -tags $tag
    set exx $sep
  }
  return [list $tag $exx $exy]
} ;# end draw_line


# ---------------------------------------------------------------------------
# Draw a sequence of terms from right to left.
# ---------------------------------------------------------------------------
#
proc draw_backwards_line {lx} {
  global LWIDTH
  global tagcnt
  incr tagcnt
  set tag x$tagcnt

  set sep $::HSEP
  set exx 0
  set exy 0
  set lb {}
  set n [llength $lx]
  for {set i [expr {$n-1}]} {$i>=0} {incr i -1} {
    lappend lb [lindex $lx $i]
  }
  foreach term $lb {
    set m [draw_diagram $term]
    foreach {t texx texy} $m break
    foreach {tx0 ty0 tx1 ty1} [.c bbox $t] break
    set w [expr {$tx1-$tx0}]
    if {$exx>0} {
      set xn [expr {$exx+$sep}]
      .c move $t $xn 0
      .c create line $exx $exy $xn $exy -tags $tag -width $LWIDTH -arrow first
      set exx [expr {$xn+$texx}]
    } else {
      set exx $texx
    }
    set exy $texy
    .c addtag $tag withtag $t
    .c dtag $t $t
  }
  if {$exx==0} {
    .c create line 0 0 $sep 0 -width $LWIDTH -tags $tag
    set exx $sep
  }
  return [list $tag $exx $exy]
} ;# end draw_backwards_line


# ---------------------------------------------------------------------------
# Draw a sequence of terms from top to bottom.
# ---------------------------------------------------------------------------
#
proc draw_stack {indent lx} {
  global tagcnt RADIUS VSEP LWIDTH
  incr tagcnt
  set tag x$tagcnt

  set sep [expr {$VSEP*2}]
  set btm 0
  set n [llength $lx]
  set i 0
  set next_bypass_y 0

  foreach term $lx {
    set bypass_y $next_bypass_y
    if {$i>0 && $i<$n && [llength $term]>1 &&
        ([lindex $term 0]=="opt" || [lindex $term 0]=="optx")} {
      set bypass 1
      set term "line [lrange $term 1 end]"
    } else {
      set bypass 0
      set next_bypass_y 0
    }
    set m [draw_diagram $term]
    foreach {t exx exy} $m break
    foreach {tx0 ty0 tx1 ty1} [.c bbox $t] break
    if {$i==0} {
      set btm $ty1
      set exit_y $exy
      set exit_x $exx
    } else {
      set enter_y [expr {$btm - $ty0 + $sep*2 + 2}]
      if {$bypass} {set next_bypass_y [expr {$enter_y - $RADIUS}]}
      set enter_x [expr {$sep + $indent}]
      set back_y [expr {$btm + $sep + 1}]
      if {$bypass_y>0} {
         set mid_y [expr {($bypass_y+$RADIUS+$back_y)/2}]
         .c create line $bypass_x $bypass_y $bypass_x $mid_y \
            -width $LWIDTH -tags $tag -arrow last
         .c create line $bypass_x $mid_y $bypass_x [expr {$back_y+$RADIUS}] \
             -tags $tag -width $LWIDTH
      }
      .c move $t $enter_x $enter_y
      set e2 [expr {$exit_x + $sep}]
      .c create line $exit_x $exit_y $e2 $exit_y \
            -width $LWIDTH -tags $tag
      draw_right_turnback $tag $e2 $exit_y $back_y
      set e3 [expr {$enter_x-$sep}]
      set bypass_x [expr {$e3-$RADIUS}]
      set emid [expr {($e2+$e3)/2}]
      .c create line $e2 $back_y $emid $back_y \
                 -width $LWIDTH -tags $tag -arrow last
      .c create line $emid $back_y $e3 $back_y \
                 -width $LWIDTH -tags $tag
      set r2 [expr {($enter_y - $back_y)/2.0}]
      draw_left_turnback $tag $e3 $back_y $enter_y down
      .c create line $e3 $enter_y $enter_x $enter_y \
                 -arrow last -width $LWIDTH -tags $tag
      set exit_x [expr {$enter_x + $exx}]
      set exit_y [expr {$enter_y + $exy}]
    }
    .c addtag $tag withtag $t
    .c dtag $t $t
    set btm [lindex [.c bbox $tag] 3]
    incr i
  }
  if {$bypass} {
    set fwd_y [expr {$btm + $sep + 1}]
    set mid_y [expr {($next_bypass_y+$RADIUS+$fwd_y)/2}]
    set descender_x [expr {$exit_x+$RADIUS}]
    .c create line $bypass_x $next_bypass_y $bypass_x $mid_y \
        -width $LWIDTH -tags $tag -arrow last
    .c create line $bypass_x $mid_y $bypass_x [expr {$fwd_y-$RADIUS}] \
        -tags $tag -width $LWIDTH
    .c create arc $bypass_x [expr {$fwd_y-2*$RADIUS}] \
                  [expr {$bypass_x+2*$RADIUS}] $fwd_y \
        -width $LWIDTH -start 180 -extent 90 -tags $tag -style arc
    .c create arc [expr {$exit_x-$RADIUS}] $exit_y \
                  $descender_x [expr {$exit_y+2*$RADIUS}] \
        -width $LWIDTH -start 90 -extent -90 -tags $tag -style arc
    .c create arc $descender_x [expr {$fwd_y-2*$RADIUS}] \
                  [expr {$descender_x+2*$RADIUS}] $fwd_y \
        -width $LWIDTH -start 180 -extent 90 -tags $tag -style arc
    set exit_x [expr {$exit_x+2*$RADIUS}]
    set half_x [expr {($exit_x+$indent)/2}]
    .c create line [expr {$bypass_x+$RADIUS}] $fwd_y $half_x $fwd_y \
        -width $LWIDTH -tags $tag -arrow last
    .c create line $half_x $fwd_y $exit_x $fwd_y \
        -width $LWIDTH -tags $tag
    .c create line $descender_x [expr {$exit_y+$RADIUS}] \
                   $descender_x [expr {$fwd_y-$RADIUS}] \
        -width $LWIDTH -tags $tag -arrow last
    set exit_y $fwd_y
  }
  set width [lindex [.c bbox $tag] 2]
  return [list $tag $exit_x $exit_y]
} ;# end draw_stack


# ---------------------------------------------------------------------------
# Draw a loop
# ---------------------------------------------------------------------------
#
proc draw_loop {forward back} {
  global LWIDTH
  global tagcnt
  incr tagcnt
  set tag x$tagcnt
  set sep $::HSEP
  set vsep $::VSEP
  if {$back in {. , ; |}} {
    set vsep 0
  } elseif {$back=="SINGLE_QUOTE"} {
    set vsep 0
  } elseif {$back=="nil"} {
    set vsep [expr {$vsep/2}]
  }

  foreach {ft fexx fexy} [draw_diagram $forward] break
  foreach {fx0 fy0 fx1 fy1} [.c bbox $ft] break
  set fw [expr {$fx1-$fx0}]
  foreach {bt bexx bexy} [draw_backwards_line $back] break
  foreach {bx0 by0 bx1 by1} [.c bbox $bt] break
  set bw [expr {$bx1-$bx0}]
  set dy [expr {$fy1 - $by0 + $vsep}]
  .c move $bt 0 $dy
  set biny $dy
  set bexy [expr {$dy+$bexy}]
  set by0 [expr {$dy+$by0}]
  set by1 [expr {$dy+$by1}]

  if {$fw>$bw} {
    if {$fexx<$fw && $fexx>=$bw} {
      set dx [expr {($fexx-$bw)/2}]
      .c move $bt $dx 0
      set bexx [expr {$dx+$bexx}]
      .c create line 0 $biny $dx $biny -width $LWIDTH -tags $bt
      .c create line $bexx $bexy $fexx $bexy -width $LWIDTH -tags $bt -arrow first
      set mxx $fexx
    } else {
      set dx [expr {($fw-$bw)/2}]
      .c move $bt $dx 0
      set bexx [expr {$dx+$bexx}]
      .c create line 0 $biny $dx $biny -width $LWIDTH -tags $bt
      .c create line $bexx $bexy $fx1 $bexy -width $LWIDTH -tags $bt -arrow first
      set mxx $fexx
    }
  } elseif {$bw>$fw} {
    set dx [expr {($bw-$fw)/2}]
    .c move $ft $dx 0
    set fexx [expr {$dx+$fexx}]
    .c create line 0 0 $dx $fexy -width $LWIDTH -tags $ft -arrow last
    .c create line $fexx $fexy $bx1 $fexy -width $LWIDTH -tags $ft
    set mxx $bexx
  }
  .c addtag $tag withtag $bt
  .c addtag $tag withtag $ft
  .c dtag $bt $bt
  .c dtag $ft $ft
  .c move $tag $sep 0
  set mxx [expr {$mxx+$sep}]
  .c create line 0 0 $sep 0 -width $LWIDTH -tags $tag
  draw_left_turnback $tag $sep 0 $biny up
  draw_right_turnback $tag $mxx $fexy $bexy
  foreach {x0 y0 x1 y1} [.c bbox $tag] break
  set exit_x [expr {$mxx+$::RADIUS}]
  .c create line $mxx $fexy $exit_x $fexy -width $LWIDTH -tags $tag
  return [list $tag $exit_x $fexy]
} ;# end draw_loop


# ---------------------------------------------------------------------------
# Draw a top-loop
# ---------------------------------------------------------------------------
#
proc draw_toploop {forward back} {
  global LWIDTH
  global tagcnt
  incr tagcnt
  set tag x$tagcnt
  set sep $::VSEP
  set vsep [expr {$sep/2}]

  foreach {ft fexx fexy} [draw_diagram $forward] break
  foreach {fx0 fy0 fx1 fy1} [.c bbox $ft] break
  set fw [expr {$fx1-$fx0}]
  foreach {bt bexx bexy} [draw_backwards_line $back] break
  foreach {bx0 by0 bx1 by1} [.c bbox $bt] break
  set bw [expr {$bx1-$bx0}]
  set dy [expr {-($by1 - $fy0 + $vsep)}]
  .c move $bt 0 $dy
  set biny $dy
  set bexy [expr {$dy+$bexy}]
  set by0 [expr {$dy+$by0}]
  set by1 [expr {$dy+$by1}]

  if {$fw>$bw} {
    set dx [expr {($fw-$bw)/2}]
    .c move $bt $dx 0
    set bexx [expr {$dx+$bexx}]
    .c create line 0 $biny $dx $biny -width $LWIDTH -tags $bt
    .c create line $bexx $bexy $fx1 $bexy -width $LWIDTH -tags $bt -arrow first
    set mxx $fexx
  } elseif {$bw>$fw} {
    set dx [expr {($bw-$fw)/2}]
    .c move $ft $dx 0
    set fexx [expr {$dx+$fexx}]
    .c create line 0 0 $dx $fexy -width $LWIDTH -tags $ft
    .c create line $fexx $fexy $bx1 $fexy -width $LWIDTH -tags $ft
    set mxx $bexx
  }
  .c addtag $tag withtag $bt
  .c addtag $tag withtag $ft
  .c dtag $bt $bt
  .c dtag $ft $ft
  .c move $tag $sep 0
  set mxx [expr {$mxx+$sep}]
  .c create line 0 0 $sep 0 -width $LWIDTH -tags $tag
  draw_left_turnback $tag $sep 0 $biny down
  draw_right_turnback $tag $mxx $fexy $bexy
  foreach {x0 y0 x1 y1} [.c bbox $tag] break
  .c create line $mxx $fexy $x1 $fexy -width $LWIDTH -tags $tag
  return [list $tag $x1 $fexy]
} ;# end draw_toploop


# ---------------------------------------------------------------------------
# Draw alternative branches
# ---------------------------------------------------------------------------
#
proc draw_or {lx} {
  global LWIDTH
  global tagcnt
  incr tagcnt
  set tag x$tagcnt
  set sep $::VSEP
  set vsep [expr {$sep/2}]
  set n [llength $lx]
  set i 0
  set mxw 0
  foreach term $lx {
    set m($i) [set mx [draw_diagram $term]]
    set tx [lindex $mx 0]
    foreach {x0 y0 x1 y1} [.c bbox $tx] break
    set w [expr {$x1-$x0}]
    if {$i>0} {set w [expr {$w+20+2*$LWIDTH-1}]}  ;# extra space for arrowheads
    if {$w>$mxw} {set mxw $w}
    incr i
  }

  set x0 0                        ;# entry x
  set x1 $sep                     ;# decender 
  set x2 [expr {$sep*2}]          ;# start of choice
  set xc [expr {$mxw/2}]          ;# center point
  set x3 [expr {$mxw+$x2}]        ;# end of choice
  set x4 [expr {$x3+$sep}]        ;# accender
  set x5 [expr {$x4+$sep}]        ;# exit x

  for {set i 0} {$i<$n} {incr i} {
    foreach {t texx texy} $m($i) break
    foreach {tx0 ty0 tx1 ty1} [.c bbox $t] break
    set w [expr {$tx1-$tx0}]
    set dx [expr {($mxw-$w)/2 + $x2}]
    if {$w>10 && $dx>$x2+10} {set dx [expr {$x2+10}]}
    .c move $t $dx 0
    set texx [expr {$texx+$dx}]
    set m($i) [list $t $texx $texy]
    foreach {tx0 ty0 tx1 ty1} [.c bbox $t] break
    if {$i==0} {
      if {$dx>$x2} {set ax last} {set ax none}
      .c create line 0 0 $dx 0 -width $LWIDTH -tags $tag -arrow $ax
      .c create line $texx $texy [expr {$x5+1}] $texy -width $LWIDTH -tags $tag
      set exy $texy
      .c create arc -$sep 0 $sep [expr {$sep*2}] \
         -width $LWIDTH -start 90 -extent -90 -tags $tag -style arc
      set btm $ty1
    } else {
      set dy [expr {$btm - $ty0 + $vsep}]
      if {$dy<2*$sep} {set dy [expr {2*$sep}]}
      .c move $t 0 $dy
      set texy [expr {$texy+$dy}]
      if {$dx>$x2} {
        .c create line $x2 $dy $dx $dy -width $LWIDTH -tags $tag -arrow last
        if {$dx<$xc-2} {set ax last} {set ax none}
        .c create line $texx $texy $x3 $texy -width $LWIDTH -tags $tag -arrow $ax
      }
      set y1 [expr {$dy-2*$sep}]
      .c create arc $x1 $y1 [expr {$x1+2*$sep}] $dy \
          -width $LWIDTH -start 180 -extent 90 -style arc -tags $tag
      set y2 [expr {$texy-2*$sep}]
      .c create arc [expr {$x3-$sep}] $y2 $x4 $texy \
          -width $LWIDTH -start 270 -extent 90 -style arc -tags $tag
      if {$i==$n-1} {
        .c create arc $x4 $exy [expr {$x4+2*$sep}] [expr {$exy+2*$sep}] \
           -width $LWIDTH -start 180 -extent -90 -tags $tag -style arc
        .c create line $x1 [expr {$dy-$sep}] $x1 $sep -width $LWIDTH -tags $tag
        .c create line $x4 [expr {$texy-$sep}] $x4 [expr {$exy+$sep}] \
               -width $LWIDTH -tags $tag
      }
      set btm [expr {$ty1+$dy}]
    }
    .c addtag $tag withtag $t
    .c dtag $t $t
  }
  return [list $tag $x5 $exy]   
} ;# end draw_or


# ---------------------------------------------------------------------------
# Draw a tail-branch
# ---------------------------------------------------------------------------
#
proc draw_tail_branch {lx} {
  global LWIDTH
  global tagcnt
  incr tagcnt
  set tag x$tagcnt
  set sep $::VSEP
  set vsep [expr {$sep/2}]
  set n [llength $lx]
  set i 0
  foreach term $lx {
    set m($i) [set mx [draw_diagram $term]]
    incr i
  }

  set x0 0                        ;# entry x
  set x1 $sep                     ;# decender 
  set x2 [expr {$sep*2}]          ;# start of choice

  for {set i 0} {$i<$n} {incr i} {
    foreach {t texx texy} $m($i) break
    foreach {tx0 ty0 tx1 ty1} [.c bbox $t] break
    set dx [expr {$x2+10}]
    .c move $t $dx 0
    foreach {tx0 ty0 tx1 ty1} [.c bbox $t] break
    if {$i==0} {
      .c create line 0 0 $dx 0 -width $LWIDTH -tags $tag -arrow last
      .c create arc -$sep 0 $sep [expr {$sep*2}] \
         -width $LWIDTH -start 90 -extent -90 -tags $tag -style arc
      set btm $ty1
    } else {
      set dy [expr {$btm - $ty0 + $vsep}]
      if {$dy<2*$sep} {set dy [expr {2*$sep}]}
      .c move $t 0 $dy
      if {$dx>$x2} {
        .c create line $x2 $dy $dx $dy -width $LWIDTH -tags $tag -arrow last
      }
      set y1 [expr {$dy-2*$sep}]
      .c create arc $x1 $y1 [expr {$x1+2*$sep}] $dy \
          -width $LWIDTH -start 180 -extent 90 -style arc -tags $tag
      if {$i==$n-1} {
        .c create line $x1 [expr {$dy-$sep}] $x1 $sep -width $LWIDTH -tags $tag
      }
      set btm [expr {$ty1+$dy}]
    }
    .c addtag $tag withtag $t
    .c dtag $t $t
  }
  return [list $tag 0 0]
} ;# end draw_tail_branch


# ---------------------------------------------------------------------------
# Draw a single diagram body
# ---------------------------------------------------------------------------
#
proc draw_diagram {spec} {
  set n [llength $spec]
  if {$n==1} {
    return [draw_bubble $spec]
  }
  if {$n==0} {
    return [draw_bubble nil]
  }
  set cmd [lindex $spec 0]
  if {$cmd=="line"} {
    return [draw_line [lrange $spec 1 end]]
  }
  if {$cmd=="stack"} {
    return [draw_stack 0 [lrange $spec 1 end]]
  }
  if {$cmd=="indentstack"} {
    return [draw_stack $::HSEP [lrange $spec 1 end]]
  }
  if {$cmd=="loop"} {
    return [draw_loop [lindex $spec 1] [lindex $spec 2]]
  }
  if {$cmd=="toploop"} {
    return [draw_toploop [lindex $spec 1] [lindex $spec 2]]
  }
  if {$cmd=="or"} {
    return [draw_or [lrange $spec 1 end]]
  }
  if {$cmd=="opt"} {
    set args [lrange $spec 1 end]
    if {[llength $args]==1} {
      return [draw_or [list nil [lindex $args 0]]]
    } else {
      return [draw_or [list nil "line $args"]]
    }
  }
  if {$cmd=="optx"} {
    set args [lrange $spec 1 end]
    if {[llength $args]==1} {
      return [draw_or [list [lindex $args 0] nil]]
    } else {
      return [draw_or [list "line $args" nil]]
    }
  }
  if {$cmd=="tailbranch"} {
    # return [draw_tail_branch [lrange $spec 1 end]]
    return [draw_or [lrange $spec 1 end]]
  }
  error "unknown operator: $cmd"
} ;# end draw_diagram


# ---------------------------------------------------------------------------
# Draw a single production
# ---------------------------------------------------------------------------
#
proc draw_graph {name spec {do_xv 1}} {
  .c delete all
  wm deiconify .
  wm title . $name
  draw_diagram "line bullet [list $spec] bullet"
  foreach {x0 y0 x1 y1} [.c bbox all] break
  .c move all [expr {2-$x0}] [expr {2-$y0}]
  foreach {x0 y0 x1 y1} [.c bbox all] break
  .c config -width $x1 -height $y1
  update
  .c postscript -file $name.ps -width [expr {$x1+2}] -height [expr {$y1+2}]
#
#  uncomment to enable GIF output (this may not work on all systems) ...
#
#  global DPI
#  exec convert -density ${DPI}x$DPI -antialias $name.ps $name.gif
#  if {$do_xv} {
#    exec xv $name.gif &
#  }
#
} ;# end draw_graph


# ---------------------------------------------------------------------------
#  Draw group of productions
# ---------------------------------------------------------------------------
#
proc draw_graphs {group} {
  set f [open all.html w]
  foreach {name graph} $group {
    if {[regexp {^X-} $name]} continue
    puts $f "<h3>$name:</h3>"
    puts $f "<img src=\"$name.gif\">"
    draw_graph $name $graph 0
    set img($name) 1
    set children($name) {}
    set parents($name) {}
  }
  close $f
  set order {}
  foreach {name graph} $group {
    lappend order $name
    unset -nocomplain v
    walk_graph_extract_names $group v
    unset -nocomplain v($name)
    foreach x [array names v] {
      if {![info exists img($x)]} continue
      lappend children($name) $x
      lappend parents($x) $name
    }
  }
  set f [open syntax_linkage.tcl w]
  foreach name [lsort [array names img]] {
    set cx [lsort $children($name)]
    set px [lsort $parents($name)]
    puts $f [list set syntax_linkage($name) [list $cx $px]]
  }
  puts $f [list set syntax_order $order]
  close $f
  wm withdraw .
} ;# end draw_graphs


# ---------------------------------------------------------------------------
#  Draw all productions
# ---------------------------------------------------------------------------
#
proc draw_all_graphs {} {
  global non_terminals
  global terminals
  global res_words
  global res_idents
  global res_symbols
  global pragmas
  global ignore_symbols
  global aliases
  global legend
  draw_graphs $non_terminals
  draw_graphs $terminals
  draw_graphs $res_words
  draw_graphs $res_idents
  draw_graphs $res_symbols
  draw_graphs $pragmas
  draw_graphs $ignore_symbols
  draw_graphs $aliases
  draw_graphs $legend
} ;# end draw_all_graphs


# ---------------------------------------------------------------------------
# Obtain the names of all productions
# ---------------------------------------------------------------------------
#
proc walk_graph_extract_names {graph varname} {
  upvar 1 $varname v
  foreach x $graph {
    set n [llength $x]
    if {$n>1} {
      walk_graph_extract_names $x v
    } elseif {[regexp {^[a-z]} $x]} {
      set v($x) 1
    }
  }
} ;# end walk_graph_extract_names

#
# END OF FILE