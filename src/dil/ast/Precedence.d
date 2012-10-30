/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity high)
module dil.ast.Precedence;

import dil.ast.NodesEnum;

/// Enumeration of precedence values.
enum PREC
{
  None,
  Expression,
  Assignment,
  Conditional,
  LogicalOr,
  LogicalAnd,
  BinaryOr,
  BinaryXor,
  BinaryAnd,
  Relational,
  Shifting,
  Addition,
  Multiplication,
  Exponentiation,
  Unary,
  Primary,
}

/// A table that maps a NodeKind to a precedence value.
static immutable PREC[NodeKind.max+1] precTable = [
  NodeKind.CondExpr: PREC.Conditional,
  NodeKind.CommaExpr: PREC.Expression,
  NodeKind.OrOrExpr:   PREC.LogicalOr,
  NodeKind.AndAndExpr: PREC.LogicalAnd,
  NodeKind.OrExpr:  PREC.BinaryOr,
  NodeKind.XorExpr: PREC.BinaryXor,
  NodeKind.AndExpr: PREC.BinaryAnd,
  NodeKind.EqualExpr:    PREC.Relational,
  NodeKind.IdentityExpr: PREC.Relational,
  NodeKind.RelExpr:      PREC.Relational,
  NodeKind.InExpr:       PREC.Relational,
  NodeKind.LShiftExpr:  PREC.Shifting,
  NodeKind.RShiftExpr:  PREC.Shifting,
  NodeKind.URShiftExpr: PREC.Shifting,
  NodeKind.PlusExpr:  PREC.Addition,
  NodeKind.MinusExpr: PREC.Addition,
  NodeKind.CatExpr:   PREC.Addition,
  NodeKind.MulExpr: PREC.Multiplication,
  NodeKind.DivExpr: PREC.Multiplication,
  NodeKind.ModExpr: PREC.Multiplication,
  NodeKind.PowExpr: PREC.Exponentiation,
  NodeKind.AssignExpr:        PREC.Assignment,
  NodeKind.LShiftAssignExpr:  PREC.Assignment,
  NodeKind.RShiftAssignExpr:  PREC.Assignment,
  NodeKind.URShiftAssignExpr: PREC.Assignment,
  NodeKind.OrAssignExpr:      PREC.Assignment,
  NodeKind.AndAssignExpr:     PREC.Assignment,
  NodeKind.PlusAssignExpr:    PREC.Assignment,
  NodeKind.MinusAssignExpr:   PREC.Assignment,
  NodeKind.DivAssignExpr:     PREC.Assignment,
  NodeKind.MulAssignExpr:     PREC.Assignment,
  NodeKind.ModAssignExpr:     PREC.Assignment,
  NodeKind.XorAssignExpr:     PREC.Assignment,
  NodeKind.CatAssignExpr:     PREC.Assignment,
  NodeKind.PowAssignExpr:     PREC.Assignment,
  NodeKind.AddressExpr:  PREC.Unary,
  NodeKind.PreIncrExpr:  PREC.Primary,
  NodeKind.PreDecrExpr:  PREC.Primary,
  NodeKind.PostIncrExpr: PREC.Primary,
  NodeKind.PostDecrExpr: PREC.Primary,
  NodeKind.DerefExpr:    PREC.Unary,
  NodeKind.SignExpr:     PREC.Unary,
  NodeKind.NotExpr:      PREC.Unary,
  NodeKind.CompExpr:     PREC.Unary,
  NodeKind.CallExpr:     PREC.Unary,
  NodeKind.NewExpr:      PREC.Unary,
  NodeKind.NewClassExpr: PREC.Unary,
  NodeKind.DeleteExpr:   PREC.Unary,
  NodeKind.CastExpr:     PREC.Unary,
  NodeKind.IndexExpr:    PREC.Unary,
  NodeKind.SliceExpr:    PREC.Unary,
  NodeKind.ModuleScopeExpr:   PREC.Primary,
  NodeKind.IdentifierExpr:    PREC.Primary,
  NodeKind.SpecialTokenExpr:  PREC.Primary,
  NodeKind.TmplInstanceExpr:  PREC.Primary,
  NodeKind.ThisExpr:          PREC.Primary,
  NodeKind.SuperExpr:         PREC.Primary,
  NodeKind.NullExpr:          PREC.Primary,
  NodeKind.DollarExpr:        PREC.Primary,
  NodeKind.BoolExpr:          PREC.Primary,
  NodeKind.IntExpr:           PREC.Primary,
  NodeKind.FloatExpr:         PREC.Primary,
  NodeKind.ComplexExpr: PREC.Addition,
  NodeKind.CharExpr:          PREC.Primary,
  NodeKind.StringExpr:        PREC.Primary,
  NodeKind.ArrayLiteralExpr:  PREC.Primary,
  NodeKind.AArrayLiteralExpr: PREC.Primary,
  NodeKind.AssertExpr:        PREC.Primary,
  NodeKind.MixinExpr:         PREC.Primary,
  NodeKind.ImportExpr:        PREC.Primary,
  NodeKind.TypeofExpr:        PREC.Primary,
  NodeKind.TypeDotIdExpr:     PREC.Primary,
  NodeKind.TypeidExpr:        PREC.Primary,
  NodeKind.IsExpr:            PREC.Primary,
  NodeKind.ParenExpr:         PREC.Primary,
  NodeKind.FuncLiteralExpr:   PREC.Primary,
  NodeKind.LambdaExpr:        PREC.Primary,
  NodeKind.TraitsExpr:        PREC.Primary,
  NodeKind.VoidInitExpr:      PREC.Primary,
  NodeKind.ArrayInitExpr:     PREC.Primary,
  NodeKind.StructInitExpr:    PREC.Primary,
  NodeKind.AsmTypeExpr:        PREC.Unary,
  NodeKind.AsmOffsetExpr:      PREC.Unary,
  NodeKind.AsmSegExpr:         PREC.Unary,
  NodeKind.AsmPostBracketExpr: PREC.Unary,
  NodeKind.AsmBracketExpr:   PREC.Primary,
  NodeKind.AsmLocalSizeExpr: PREC.Primary,
  NodeKind.AsmRegisterExpr:  PREC.Primary,
];

/// Returns the precedence value for a NodeKind.
PREC precOf(NodeKind k)
{
  return precTable[k];
}