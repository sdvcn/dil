/// Author: Aziz Köksal
/// License: GPL3
/// $(Maturity average)
module dil.ast.TypePrinter;

import dil.ast.Visitor,
       dil.ast.Node,
       dil.ast.Types,
       dil.ast.Parameters;
import dil.Enums;
import common;

/// Writes the type chain to a text buffer.
class TypePrinter : Visitor
{
  char[] text; /// The buffer that gets written to.

  /// Returns the type chain as a string.
  /// Params:
  ///   type = the type node to be traversed and printed.
  ///   outerBuffer = append to this buffer.
  char[] print(T type, char[] outerBuffer = null)
  {
    text = outerBuffer;
    visitT(type);
    return text;
  }

  alias TypeNode T;

  /// Writes parameters to the buffer.
  void writeParams(Parameters params)
  {
    assert(params !is null);
    write("(");
    size_t item_count = params.items.length;
    foreach (param; params.items)
    {
      if (param.isCVariadic)
        write("...");
      else
      {
        // Write storage class(es).
        auto lastSTC = param.tokenOfLastSTC();
        if (lastSTC) // Write storage classes.
          write(param.begin, lastSTC),
          write(" ");

        param.type && visitT(param.type);

        if (param.hasName)
          write(" "), write(param.nameStr);
        if (param.isDVariadic)
          write("...");
        if (auto v = param.defValue)
          write(" = "), write(v.begin, v.end);
      }
      --item_count && write(", "); // Skip for last item.
    }
    write(")");
  }

  void write(string text)
  {
    this.text ~= text;
  }

  void write(Token* begin, Token* end)
  {
    this.text ~= begin.textSpan(end);
  }

override:
  T visit(IntegralType t)
  {
    write(t.begin.text);
    return t;
  }

  T visit(IdentifierType t)
  {
    t.next && visitT(t.next) && write(".");
    write(t.ident.str);
    return t;
  }

  T visit(TemplateInstanceType t)
  {
    t.next && visitT(t.next) && write(".");
    write(t.ident.str), write("!");
    auto a = t.targs;
    write(a.begin, a.end);
    return t;
  }

  T visit(TypeofType t)
  {
    write(t.begin, t.end);
    return t;
  }

  T visit(PointerType t)
  {
    if (auto cfunc = t.next.Is!(CFuncType))
    { // Skip the CFuncType. Write a D-style function pointer.
      visitT(t.next.next);
      write(" function");
      writeParams(cfunc.params);
    }
    else
      visitT(t.next),
      write("*");
    return t;
  }

  T visit(ArrayType t)
  {
    visitT(t.next);
    write("[");
    if (t.isAssociative())
      visitT(t.assocType);
    /+else if (t.isDynamic())
    {}+/
    else if (t.isStatic())
      write(t.index1.begin, t.index1.end);
    else if (t.isSlice())
      write(t.index1.begin, t.index1.end),
      write(".."),
      write(t.index2.begin, t.index2.end);
    write("]");
    return t;
  }

  T visit(FunctionType t)
  {
    visitT(t.next);
    write(" function");
    writeParams(t.params);
    return t;
  }

  T visit(DelegateType t)
  {
    visitT(t.next);
    write(" delegate");
    writeParams(t.params);
    return t;
  }

  T visit(CFuncType t)
  {
    visitT(t.next);
    writeParams(t.params);
    return t;
  }

  T visit(BaseClassType t)
  {
    write(EnumString(t.prot) ~ " ");
    visitT(t.next);
    return t;
  }

  T visit(ConstType t)
  {
    write("const");
    if (t.next !is null)
    {
      write("(");
      visitT(t.next);
      write(")");
    }
    return t;
  }

  T visit(ImmutableType t)
  {
    write("immutable");
    if (t.next !is null)
    {
      write("(");
      visitT(t.next);
      write(")");
    }
    return t;
  }

  T visit(SharedType t)
  {
    write("shared");
    if (t.next !is null)
    {
      write("(");
      visitT(t.next);
      write(")");
    }
    return t;
  }
}
