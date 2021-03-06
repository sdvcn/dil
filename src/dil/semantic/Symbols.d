/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module dil.semantic.Symbols;

import dil.ast.Expression;
import dil.semantic.Symbol,
       dil.semantic.SymbolTable,
       dil.semantic.Types;
import dil.lexer.IdTable;
import dil.Enums,
       dil.String;
import common;

/// Declaration symbol.
abstract class DeclarationSymbol : Symbol
{
  Protection prot; /// The protection.
  StorageClass stcs; /// The storage classes.
  LinkageType linkage; /// The linkage type.

  this(SYM sid, Identifier* name, SLoc loc)
  {
    super(sid, name, loc);
  }

  override cstring toMangle()
  {
    return toMangle(this, linkage);
  }

  static cstring toMangle(Symbol s, LinkageType linkage)
  {
    cstring toCppMangle(Symbol s){ /+TODO+/ return ""; }

    cstring m;
    if (!s.parent || s.parent.isModule())
      switch (linkage)
      {
      case LinkageType.D:
        break;
      case LinkageType.C,
           LinkageType.Windows,
           LinkageType.Pascal:
        m = s.name.str;
        break;
      case LinkageType.Cpp:
        version(D2)version(Windows)
        goto case LinkageType.C; // D2 on Windows

        m = toCppMangle(s);
        break;
      case LinkageType.None:
        // TODO: issue forward declaration error?
        goto case LinkageType.C;
      default: assert(0);
      }
    if (!m)
      m = "_D" ~ toMangle2(s);
    return m;
  }

  static cstring toMangle2(Symbol s)
  { // Recursive function.
    cstring m;
    Symbol s2 = s;
    for (; s2; s2 = s2.parent)
      if (s2.name is Ident.Empty)
        m = "0" ~ m;
      else if (s2 !is s && s2.isFunction())
      {
        m = toMangle2(s2) ~ m; // Recursive call.
        break;
      }
      else
      {
        auto id = s2.name.str;
        m = itoa(id.length) ~ id ~ m;
      }

    auto fs = s.isFunction() ? s.to!(FunctionSymbol) : null;

    if (fs /+&& (fs.needThis() || fs.isNested())+/) // FIXME:
      m ~= 'M'; // Mangle char for member/nested functions.
    if (auto t = cast(Type)s.getType())
      if (t.mangled)
        m ~= t.mangled;

    return m;
  }
}

/// A symbol that has its own scope with a symbol table.
class ScopeSymbol : Symbol
{
  SymbolTable symbolTable; /// The symbol table.
  Symbol[] members; /// The member symbols (in lexical order.)

  /// Constructs a ScopeSymbol object.
  this(SYM sid, Identifier* name, SLoc loc)
  {
    super(sid, name, loc);
  }

  /// Constructs a ScopeSymbol object with the SYM.Scope ID.
  this(Identifier* name = Ident.Empty, SLoc loc = SLoc.init)
  {
    super(SYM.Scope, name, loc);
  }

  /// Looks up name in the table.
  Symbol lookup(Identifier* name)
  {
    return symbolTable.lookup(name);
  }

  /// Looks up a symbol in the table using its string hash.
  Symbol lookup(hash_t hash)
  {
    return symbolTable.lookup(hash);
  }

  /// Inserts a symbol into the table.
  void insert(Symbol s, Identifier* name)
  {
    symbolTable.insert(s, name);
    members ~= s;
  }
}

/// A module symbol.
class ModuleSymbol : ScopeSymbol
{
  ModuleInfoSymbol varminfo; /// The ModuleInfo for this module.

  this(Identifier* name = null, SLoc loc = SLoc.init)
  {
    super(SYM.Module, name, loc);
  }
}

/// A package symbol.
class PackageSymbol : ScopeSymbol
{
  this(Identifier* name = null, SLoc loc = SLoc.init)
  {
    super(SYM.Package, name, loc);
  }
}

/// Aggregates have function and field members.
abstract class AggregateSymbol : ScopeSymbol
{
  Type type;
  FunctionSymbol[] funcs;
  VariableSymbol[] fields;
  AliasSymbol[] aliases; /// AliasThis symbols.

  this(SYM sid, Identifier* name, SLoc loc)
  {
    super(sid, name, loc);
  }

override:
  void insert(Symbol s, Identifier* ident)
  {
    if (s.isVariable())
      // Append variable to fields.
      fields ~= s.to!(VariableSymbol);
    else if (s.isFunction())
      // Append function to funcs.
      funcs ~= s.to!(FunctionSymbol);
    super.insert(s, ident);
  }

  Type getType()
  {
    return type;
  }

  cstring toMangle()
  {
    return Symbol.toMangle(this);
  }
}

/// A class symbol.
class ClassSymbol : AggregateSymbol
{
  ClassSymbol base; /// The inherited base class.
  InterfaceSymbol[] ifaces; /// The inherited interfaces.

  TypeInfoSymbol vartinfo; /// The TypeInfo of this class.

  this(Identifier* name, SLoc loc)
  {
    super(SYM.Class, name, loc);
    this.type = new TypeClass(this);
  }
}

/// Special classes, e.g.: Object, ClassInfo, ModuleInfo etc.
class SpecialClassSymbol : ClassSymbol
{
  this(Identifier* name, SLoc loc)
  {
    super(name, loc);
  }

  /// Handle mangling differently for special classes.
  override cstring toMangle()
  {
    auto parent_save = parent;
    parent = null;
    auto m = super.toMangle();
    parent = parent_save;
    return m;
  }
}

/// An interface symbol.
class InterfaceSymbol : ClassSymbol
{
  this(Identifier* name, SLoc loc)
  {
    super(name, loc);
    this.sid = SYM.Interface;
    this.type = new TypeClass(this);
  }
}

/// A struct symbol.
class StructSymbol : AggregateSymbol
{
  bool isAnonymous;
  this(Identifier* name, SLoc loc)
  {
    super(SYM.Struct, name, loc);
    this.type = new TypeStruct(this);
    this.isAnonymous = name is null;
  }
}

/// A union symbol.
class UnionSymbol : StructSymbol
{
  bool isAnonymous;
  this(Identifier* name, SLoc loc)
  {
    super(name, loc);
    this.sid = SYM.Union;
    this.type = new TypeStruct(this);
    this.isAnonymous = name is null;
  }
}

/// An enum symbol.
class EnumSymbol : ScopeSymbol
{
  TypeEnum type;
  bool isAnonymous;
  this(Identifier* name, SLoc loc)
  {
    super(SYM.Enum, name, loc);
    this.type = new TypeEnum(this);
    this.isAnonymous = name is null;
  }

  void setType(TypeEnum type)
  {
    this.type = type;
  }

  override Type getType()
  {
    return type;
  }
}

/// A function symbol.
class FunctionSymbol : ScopeSymbol
{
  Protection prot; /// The protection.
  StorageClass stcs; /// The storage classes.
  LinkageType linkage; /// The linkage type.
  TypeFunction type; /// The type of this function.
  ParametersSymbol params; /// The parameters of this function.

  this(Identifier* name, SLoc loc)
  {
    super(SYM.Function, name, loc);
  }

  override Type getType()
  {
    return type;
  }

  cstring toText()
  { // := ReturnType Name ParameterList
    return type.retType.toString() ~ name.str ~ params.toString();
  }

  override cstring toMangle()
  {
    if (isDMain())
      return "_Dmain";
    if (isWinMain() || isDllMain())
      return name.str;
    return DeclarationSymbol.toMangle(this, linkage);
  }

  bool isDMain()
  {
    return name is Ident.main && linkage != LinkageType.C && !isMember();
  }

  bool isWinMain()
  {
    return name is Ident.WinMain && linkage != LinkageType.C && !isMember();
  }

  bool isDllMain()
  {
    return name is Ident.DllMain && linkage != LinkageType.C && !isMember();
  }

  bool isMember()
  { // TODO
    return false;
  }
}

/// The parameter symbol.
class ParameterSymbol : Symbol
{
  StorageClass stcs; /// Storage classes.
  VariadicStyle variadic; /// Variadic style.
  Type ptype; /// The parameter's type.
  Expression defValue; /// The default initialization value.

  TypeParameter type; /// Type of this symbol.

  this(Type ptype, Identifier* name,
    StorageClass stcs, VariadicStyle variadic, SLoc loc)
  {
    super(SYM.Parameter, name, loc);
    this.stcs = stcs;
    this.variadic = variadic;
    this.ptype = ptype;
    this.type = new TypeParameter(ptype, stcs, variadic);
  }

  cstring toText()
  { // := StorageClasses? ParamType? ParamName? (" = " DefaultValue)? "..."?
    char[] s;
    foreach (stc; EnumString.all(stcs))
      s ~= stc ~ " ";
    if (type)
      s ~= type.toString();
    if (name !is Ident.Empty)
      s ~= name.str;
    if (defValue)
      s ~= " = " ~ defValue.toText();
    else if (variadic)
      s ~= "...";
    assert(s.length, "empty parameter?");
    return s;
  }

  override cstring toMangle()
  {
    return type.toMangle();
  }
}

/// A list of ParameterSymbol objects.
class ParametersSymbol : Symbol
{
  ParameterSymbol[] params; /// The parameters.
  TypeParameters type; /// Type of this symbol.

  this(ParameterSymbol[] params, SLoc loc = SLoc.init)
  {
    super(SYM.Parameters, Ident.Empty, loc);
    this.params = params;
    auto ptypes = new TypeParameter[params.length];
    foreach (i, p; params)
      ptypes[i] = p.type;
    this.type = new TypeParameters(ptypes);
  }

  /// Returns the variadic style of the last parameter.
  VariadicStyle getVariadic()
  {
    return type.getVariadic();
  }

  cstring toText()
  { // := "(" ParameterList ")"
    char[] s;
    s ~= "(";
    foreach (i, p; params) {
      if (i) s ~= ", "; // Append comma if more than one param.
      s ~= p.toString();
    }
    s ~= ")";
    return s;
  }

  override cstring toMangle()
  {
    return type.toMangle();
  }
}

/// A variable symbol.
class VariableSymbol : Symbol
{
  Protection prot; /// The protection.
  StorageClass stcs; /// The storage classes.
  LinkageType linkage; /// The linkage type.

  Type type; /// The type of this variable.
  Expression value; /// The value of this variable.

  this(Identifier* name,
       Protection prot, StorageClass stcs, LinkageType linkage,
       SLoc loc)
  {
    super(SYM.Variable, name, loc);

    this.prot = prot;
    this.stcs = stcs;
    this.linkage = linkage;
  }

  this(Identifier* name, SLoc loc)
  {
    this(name, Protection.None, StorageClass.None, LinkageType.None, loc);
  }

  override cstring toMangle()
  {
    return DeclarationSymbol.toMangle(this, linkage);
  }
}

/// An enum member symbol.
class EnumMemberSymbol : VariableSymbol
{
  this(Identifier* name,
       Protection prot, StorageClass stcs, LinkageType linkage,
       SLoc loc)
  {
    super(name, prot, stcs, linkage, loc);
    this.sid = SYM.EnumMember;
  }
}

/// A this-pointer symbol for member functions (or frame pointers.)
class ThisSymbol : VariableSymbol
{
  this(Type type, SLoc loc)
  {
    super(Keyword.This, loc);
    this.type = type;
  }
}

/// A ClassInfo variable symbol.
class ClassInfoSymbol : VariableSymbol
{
  ClassSymbol clas; /// The class to provide info for.
  /// Constructs a ClassInfoSymbol object.
  ///
  /// Params:
  ///   clas = ClassInfo for this class.
  ///   classClassInfo = The global ClassInfo class from object.d.
  this(ClassSymbol clas, ClassSymbol classClassInfo)
  {
    super(clas.name, clas.loc);
    this.type = classClassInfo.type;
    this.clas = clas;
    this.stcs = StorageClass.Static;
  }

//   Something toSomething() // TODO:
//   { return null; }
}

/// A ModuleInfo variable symbol.
class ModuleInfoSymbol : VariableSymbol
{
  ModuleSymbol modul; /// The module to provide info for.
  /// Constructs a ModuleInfoSymbol object.
  ///
  /// Params:
  ///   modul = ModuleInfo for this module.
  ///   classModuleInfo = The global ModuleInfo class from object.d.
  this(ModuleSymbol modul, ClassSymbol classModuleInfo)
  {
    super(modul.name, modul.loc);
    this.type = classModuleInfo.type;
    this.modul = modul;
    this.stcs = StorageClass.Static;
  }

//   Something toSomething() // TODO:
//   { return null; }
}

/// A TypeInfo variable symbol.
class TypeInfoSymbol : VariableSymbol
{
  Type titype; /// The type to provide info for.
  /// Constructs a TypeInfo object.
  ///
  /// The variable is of type TypeInfo and its name is mangled.
  /// E.g.:
  /// ---
  /// TypeInfo _D10TypeInfo_a6__initZ; // For type "char".
  /// ---
  /// Params:
  ///   titype = TypeInfo for this type.
  ///   name  = The mangled name of this variable.
  ///   classTypeInfo = The global TypeInfo class from object.d.
  this(Type titype, Identifier* name, ClassSymbol classTypeInfo)
  { // FIXME: provide the node of TypeInfo for now.
    // titype has no node; should every Type get one?
    super(name, classTypeInfo.loc);
    this.type = classTypeInfo.type;
    this.titype = titype;
    this.stcs = StorageClass.Static;
    this.prot = Protection.Public;
    this.linkage = LinkageType.C;
  }

//   Something toSomething() // TODO:
//   {
//     switch (titype.tid)
//     {
//     case TYP.Char: break;
//     case TYP.Function: break;
//     // etc.
//     default:
//     }
//     return null;
//   }
}

// TODO: let dil.semantic.Types.Type inherit from Symbol?
/// A type symbol.
class TypeSymbol : Symbol
{
  Type type; /// Wrapper around this type.

  this(Type type)
  {
    super(SYM.Type, null, SLoc.init);
    this.type = type;
  }
}

/// A tuple symbol.
class TupleSymbol : Symbol
{
  TypeTuple type; /// The type of this tuple.
  Symbol[] items; /// The items in this tuple.

  this(Symbol[] items, Identifier* name, SLoc loc)
  {
    super(SYM.Tuple, name, loc);
  }

  /// Returns the type only when all elements are types, otherwise null.
  override Type getType()
  {
    if (!type && hasOnlyTypes())
      type = makeTypeTuple();
    return type;
  }

  /// Returns true if all elements are types (also if the tuple is empty.)
  bool hasOnlyTypes()
  {
    foreach (item; items)
      if (!item.isType())
        return false;
    return true;
  }

  /// Creates a TypeTuple instance from the items of this tuple.
  TypeTuple makeTypeTuple()
  in { assert(hasOnlyTypes()); }
  body
  {
    auto types = new Type[items.length]; // Allocate exact amount of types.
    foreach (i, item; items)
      types[i] = item.to!(TypeSymbol).type;
    return new TypeTuple(types);
  }

  override cstring toMangle()
  {
    return DeclarationSymbol.toMangle(this, LinkageType.D /+FIXME+/);
  }
}

// class ExprTupleSymbol : TupleSymbol
// {
//   // TODO:
// }

/// An alias symbol.
class AliasSymbol : Symbol
{
  Type aliasType;
  Symbol aliasSym;

  this(Identifier* name, SLoc loc)
  {
    super(SYM.Alias, name, loc);
  }

  override cstring toMangle()
  {
    return DeclarationSymbol.toMangle(this, LinkageType.D /+FIXME+/);
  }
}

/// A typedef symbol.
class TypedefSymbol : Symbol
{
  this(Identifier* name, SLoc loc)
  {
    super(SYM.Typedef, name, loc);
  }

  override cstring toMangle()
  {
    return Symbol.toMangle(this);
  }
}

/// A template symbol.
class TemplateSymbol : ScopeSymbol
{
  AliasSymbol[] aliases; /// AliasThis symbols.
  this(Identifier* name, SLoc loc)
  {
    super(SYM.Template, name, loc);
  }
}

/// A template instance symbol.
class TemplInstanceSymbol : ScopeSymbol
{
  // TemplArgSymbol[] tiArgs;
  TemplateSymbol tplSymbol;
  this(Identifier* name, SLoc loc)
  {
    super(SYM.TemplateInstance, name, loc);
  }

  override cstring toMangle()
  { // := ParentMangle? NameMangleLength NameMangle
    if (name is Ident.Empty)
    {} // TODO: ?
    cstring pm; // Parent mangle.
    if (!tplSymbol)
    {} // Error: undefined
    else if (tplSymbol.parent)
    {
      pm = tplSymbol.parent.toMangle();
      if (pm.length >= 2 && pm[0..2] == "_D")
        pm = pm[2..$]; // Skip the prefix.
    }
    cstring id = name.str;
    return pm ~ itoa(id.length) ~ id;
  }
}

/// A template mixin symbol.
class TemplMixinSymbol : TemplInstanceSymbol
{
  this(Identifier* name, SLoc loc)
  {
    super(name, loc);
    this.sid = SYM.TemplateMixin;
  }

  override cstring toMangle()
  {
    return Symbol.toMangle(this);
  }
}

/// A list of symbols that share the same identifier.
///
/// These can be functions, templates and aggregates with template parameter lists.
class OverloadSet : Symbol
{
  Symbol[] symbols;

  this(Identifier* name, SLoc loc)
  {
    super(SYM.OverloadSet, name, loc);
  }

  void add(Symbol s)
  {
    symbols ~= s;
  }
}
