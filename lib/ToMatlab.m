
(****** ToMatlab.mth -- Mathematica expressions into Matlab form *************)
(* 

% $Rev: 97 $
% $Date: 2016-09-23 12:00:42 -0700 (Fri, 23 Sep 2016) $
% $LastChangedBy: jlperla $
Originally from http://library.wolfram.com/infocenter/MathSource/577/

ToMatlab[expr] 

Converts the expression expr into matlab syntax and
returns it as a String.

ToMatlab[expr, name] 

Returns an assignment of expr into name as a String. name can be also
a more complicated string, e.g.,

	ToMatlab[If[t,a,b],"function y=iffun(t,a,b)\ny"].

The special symbol Colon can be used to denote the matlab colon
operator :, and Colon[a,b] for a:b, Colon[a,b,c] for a:b:c.


WriteMatlab[expr, file]
WriteMatlab[expr, file, name] 

Writes the expr in matlab form into the given file. The second form
makes this an assignment into the variable name. Example:

	f = OpenWrite["file.m"]; 
	WriteMatlab[Cos[x]-x, f, y]; 
	Close[f];

The file argument can also be a String that gives the name of the
file:

	WriteMatlab[Cos[x]-x, "file.m", y]; 

achieves the same result as the previous example (but this limits one
expression per file).


PrintMatlab[expr]
PrintMatlab[expr, name] 

is like ToMatlab but instead of returning the String, it is printed on
the screen.


RulesToMatlab[rules] 

Where rules is the result from Solve or NSolve: converts the rules into
individual assignment statements.

*)

(* (C) 1997-1999 Harri Ojanen  
	harri.ojanen@iki.fi
	http://www.iki.fi/~harri.ojanen/ *)

(* Last modified April 2 1999 *)

$constant$subscripts = {""}; (* make it empty so ToMatlab doesn't fail*)

(* BeginPackage["MatlabUtils`ToMatlab`"] *)
	
ToMatlab::usage = 
"ToMatlab[expr]  converts the expression  expr  into matlab syntax and returns it as a String.\nToMatlab[expr, name]  returns an assignment of  expr  into  name as a String. name can be also a more complicated string, e.g., ToMatlab[If[t,a,b],\"function y=iffun(t,a,b)\\ny\"].\nThe special symbol Colon can be used to denote the matlab colon operator :, and Colon[a,b] for a:b, Colon[a,b,c] for a:b:c.\nSee also  WriteMatlab  and  PrintMatlab.\nAll functions accept an optional last argument that is the maximum line width."

WriteMatlab::usage =
"WriteMatlab[expr, file]  or  WriteMatlab[expr, file, name] Writes the  expr  in matlab form into the given file. The second form makes this an assignment into the variable  name.\nExample: f = OpenWrite[\"file.m\"]; WriteMatlab[Cos[x]-x, f, y]; Close[f];\nThe file argument can also be a String that gives the name of the file: WriteMatlab[Cos[x]-x, \"file.m\", y]; achieves the same result as the previous example (but this limits one expression per file).\nSee also  ToMatlab  and  PrintMatlab."

PrintMatlab::usage =
"PrintMatlab[expr]  or  PrintMatlab[expr, name]  is like  ToMatlab but instead of returning the String, it is printed on the screen. See also  ToMatlab  and  WriteMatlab."

RulesToMatlab::usage =
"RulesToMatlab[rules] where rules is from Solve or NSolve converts the rules into individual assignment statements."

(*SetMargin::usage = "SetMargin[margin]"
RestoreMargin::usage = "RestoreMargin[]"*)

(* Begin["`Private`"] *)

WriteMatlab[e_, file_OutputStream] :=
    (WriteString[file, ToMatlab[e,72]];)

WriteMatlab[e_, file_OutputStream, name_] :=
    (WriteString[file, ToMatlab[e,name,72]];)	    /; (!NumberQ[name])

WriteMatlab[e_, file_String] :=
    (Block[{f = OpenWrite[file]},
	WriteString[f, ToMatlab[e,72]];
	Close[f];];)

WriteMatlab[e_, file_String, name_] :=
    (Block[{f = OpenWrite[file]},
	WriteString[f, ToMatlab[e,name,72]];
	Close[f];];)	    /; (!NumberQ[name])

WriteMatlab[e_, file_OutputStream, margin_Integer] :=
    (WriteString[file, ToMatlab[e,margin]];)

WriteMatlab[e_, file_OutputStream, name_, margin_Integer] :=
    (WriteString[file, ToMatlab[e,name,margin]];)

WriteMatlab[e_, file_String, margin_Integer] :=
    (Block[{f = OpenWrite[file]},
	WriteString[f, ToMatlab[e,margin]];
	Close[f];];)

WriteMatlab[e_, file_String, name_, margin_Integer] :=
    (Block[{f = OpenWrite[file]},
	WriteString[f, ToMatlab[e,name,margin]];
	Close[f];];)



PrintMatlab[e_] := 
    (Print[ToMatlab[e, 60]];)

PrintMatlab[e_, name_] := 
    (Print[ToMatlab[e, name, 60]];)	    /; (!NumberQ[name])

PrintMatlab[e_, margin_Integer] := 
    (Print[ToMatlab[e, margin]];)

PrintMatlab[e_, name_, margin_Integer] := 
    (Print[ToMatlab[e, name, margin]];)

ToMatlab[e_] := ETKRules@ETKRules@foldlines[ToMatlabaux[e] <> ";\n"]

ToMatlab[e_, name_] :=
    ETKRules@ETKRules@ToMatlabaux[name] <> "=" <> ETKRules@ETKRules@foldlines[ToMatlabaux[e] <> ";\n"]   /; 
		(!NumberQ[name])

ToMatlab[e_, margin_Integer] :=
    Block[{sSs},
	SetMargin[margin];
	sSs = ETKRules@ETKRules@foldlines[ToMatlabaux[e] <> ";\n"]
	RestoreMargin[];
	sSs]

ToMatlab[e_, name_, margin_Integer] :=
    Block[{sSs},
	SetMargin[margin];
	sSs = ETKRules@ETKRules@ToMatlabaux[name] <> "=" <> ETKRules@ETKRules@foldlines[ToMatlabaux[e] <> ";\n"]
	RestoreMargin[];
	sSs]


DropLastTwo[sSs_] := StringDrop[sSs, -2];

WrappedToMatlabaux[e_] := ETKRules@ETKRules@ToMatlabaux[e];
	
RulesToMatlab[l_List] :=
    If[Length[l] === 0,
	"",
	Block[{sSs = RulesToMatlab[ l[[1]] ]},
	    Do[sSs = sSs <> RulesToMatlab[ l[[i]] ], {i, 2, Length[l]}];
	    sSs]]

RulesToMatlab[Rule[x_Symbol, a_]]:=
	ToMatlab[a, DropLastTwo@ToMatlab[x]] 

	
RulesToMatlab[Rule[x_[arg_?ConstantOrSpecialSymbolQ], a_]]:=
	ToMatlab[a,DropLastTwo@ToMatlab[x[arg]]]

RulesToMatlab[(Rule | RuleDelayed)[h_[a__], rhs_]] := WrappedToMatlabaux[h] <> " = @(" <> ToString@Row[WrappedToMatlabaux /@ ({a} /. Pattern -> (# &)), ","] <> ") " <> WrappedToMatlabaux[rhs] <> ";\n"

(*** Numbers and strings *****************************************************)

(* exp = {\[Alpha], \[Epsilon], \[Chi], \[Delta], \[Rho], \[Tau], \
\[Theta], \[Psi], \[CapitalPsi], \[CapitalDelta], \[CapitalTheta], \
\[Upsilon], \[Iota], \[Omega], \[CapitalOmega], \[DoubledPi], \
\[CapitalPi], \[Alpha], \[Sigma], \[CapitalSigma], \[Delta], \
\[CapitalDelta], \[Phi], \[CapitalPhi], \[Gamma], \[CapitalGamma], \
\[Eta], \[CurlyPhi], \[Kappa], \[Lambda], \[CapitalLambda], \[Zeta], \
\[Xi], \[CapitalXi], \[Chi],  \[Beta], \[Nu], \[Mu], \[Stigma], \
\[CapitalStigma], }  // ToString // FullForm *)

matlab$symbol$conversion$rules := {"\[Alpha]" -> "alpha", "\[Epsilon]" -> "epsilon", "\[Chi]" -> "chi", "\[Delta]" -> "delta", "\[Rho]" -> "rho", "\[Tau]" -> "tau", 
"\[Theta]" -> "theta", "\[Psi]" -> "psi", "\[CapitalPsi]" -> "Psi", "\[CapitalDelta]" -> "Delta", "\[CapitalTheta]" -> "Theta", 
"\[Upsilon]" -> "upsilon", "\[Iota]" -> "iota", "\[Omega]" -> "omega", "\[CapitalOmega]" -> "Omega", "\[DoubledPi]" -> "pi", "\[Pi]" -> "pi", 
"\[CapitalPi]" -> "Pi", "\[Alpha]" -> "alpha", "\[Sigma]" -> "sigma", "\[CapitalSigma]" -> "Sigma", "\[Delta]" -> "delta", 
"\[CapitalDelta]" -> "Delta", "\[Phi]" -> "phi", "\[CapitalPhi]" -> "Phi", "\[Gamma]" -> "gamma", "\[CapitalGamma]" -> "Gamma", 
"\[Eta]" -> "eta", "\[Kappa]" -> "kappa", "\[Lambda]" -> "lambda", "\[CapitalLambda]" -> "Lambda", "\[Zeta]" -> "zeta", 
"\[Xi]" -> "xi", "\[CapitalXi]" -> "Xi", "\[Chi]" -> "chi",  "\[Beta]" -> "beta", "\[Nu]" -> "nu", "\[Mu]" -> "mu", "\[Stigma]" -> "varsigma", 
"\[CapitalStigma]" -> "Varsigma"};

special$symbols = {"bar","hat","vec","underbar","plus","minus","star","tilde","bar"}
SpecialSymbolQ[sSs_]:= StringMatchQ[sSs, special$symbols];
ETKRules[sSs_] := StringReplace[sSs, Union[matlab$symbol$conversion$rules, other$rules]];
ConstantSubscriptQ[sSs_]:= StringMatchQ[sSs, $constant$subscripts];
ConstantOrSpecialSymbolQ[exp_] := SpecialSymbolQ[ToString[exp]] || ConstantSubscriptQ[ToString[exp]];
NotConstantOrSpecialSymbolQ[exp_] := !ConstantOrSpecialSymbolQ[exp];

other$rules := {
"$" -> "_",
"(bar)" -> "_bar",
"(hat)" -> "_hat",
"(vec)" -> "_vec",
"(underbar)" -> "_underbar",
"(plus)" -> "_plus",
"(minus)" -> "_minus",
"(star)" -> "_star",
"(tilde)" -> "_tilde",	
f_ ~~ "("~~ sub_ ~~ ")"~~ {Whitespace | ""} ~~"(" ~~ arg__ ~~ ")" -> f~~"_" ~~sub ~~ "(" ~~ arg ~~")",(* General indicies on functions*)
f_ ~~ "("~~ sub_?ConstantSubscriptQ ~~ ")"-> f~~"_" ~~ sub (* Subscripts if in list given*)
(*
f_ ~~ "("~~ sub_ ~~ ")(" ~~ arg__ ~~ ")" -> f~~"_" ~~sub ~~ "(" ~~ arg ~~")", (* General indicies on functions*)
f_ ~~ "("~~ sub_?InConstantSubscripts ~~ ")"~~ {Whitespace | ""} ~~"(" -> f~~"_" ~~ sub, (* Subscripts if in list given*)
f_ ~~ "("~~ sub_?InConstantSubscripts ~~ ")"~~ {Whitespace | ""} ~~"(" ~~ arg__ ~~ ")" -> f~~"_" ~~sub ~~ "(" ~~ arg ~~")" (* General indicies on functions with subscript*)
*)
};


ToMatlabaux[sSs_String] := sSs

ToMatlabaux[n_Integer] :=
    If[n >= 0, ToString[n], "(" <> ToString[n] <> ")"]

(*ToMatlabaux[r_Rational] := 
    "(" <> ToMatlabaux[Numerator[r]] <> "/" <>
           ToMatlabaux[Denominator[r]] <> ")"*)

ToMatlabaux[r_Rational] := 
    "(" <> ToString[Numerator[r]] <> "/" <>
           ToString[Denominator[r]] <> ")"


ToMatlabaux[r_Real] := 
    Block[{a = MantissaExponent[r]},
        If[r >= 0,
            ToString[N[a[[1]],18]] <> "E" <> ToString[a[[2]]],
            "(" <> ToString[N[a[[1]],18]] <> "E" <> ToString[a[[2]]] <> ")"]]

ToMatlabaux[I] := "sqrt(-1)";

ToMatlabaux[c_Complex] :=
    "(" <>
    If[Re[c] === 0,
        "",
        ToMatlabaux[Re[c]] <> "+"] <>
    If[Im[c] === 1,
        "sqrt(-1)",
        "sqrt(-1)*" <> ToMatlabaux[Im[c]] ] <> ")"



(*** Lists, vectors and matrices *********************************************)


numberMatrixQ[m_] := MatrixQ[m] && (And @@ Map[numberListQ,m])

numberListQ[l_] := ListQ[l] && (And @@ Map[NumberQ,l])


numbermatrixToMatlab[m_] :=
    Block[{i, sSs=""}, 
	For[i=1, i<=Length[m], i++,
	    sSs = sSs <> numbermatrixrow[m[[i]]];    
	    If[i < Length[m], sSs = sSs <> ";"]];
	sSs]

numbermatrixrow[l_] :=
    Block[{i, sSs=""},
	For[i=1, i<=Length[l], i++, 
	    sSs = sSs <> ToMatlabaux[l[[i]]];
	    If[i < Length[l], sSs = sSs <> ","]];
	sSs]


ToMatlabaux[l_List /; MatrixQ[l]] :=
    If[numberMatrixQ[l],
	"[" <> numbermatrixToMatlab[l] <> "]",
	"[" <> matrixToMatlab[l] <> "]"]

matrixToMatlab[m_] :=
    If[Length[m] === 1, 
        ToMatlabargs[m[[1]]],
        ToMatlabargs[m[[1]]] <> ";" <>
            matrixToMatlab[ argslistdrop[m] ] ]

ToMatlabaux[l_List] := "[" <> ToMatlabargs[l] <> "]"



(*** Symbols *****************************************************************)

ToMatlabaux[Colon] = ":"
ToMatlabaux[Abs] = "abs"
ToMatlabaux[Min] = "min"
ToMatlabaux[Max] = "max"
ToMatlabaux[Sin] = "sin"
ToMatlabaux[Cos] = "cos"
ToMatlabaux[Tan] = "tan"
ToMatlabaux[Cot] = "cot"
ToMatlabaux[Csc] = "csc"
ToMatlabaux[Sec] = "sec"
ToMatlabaux[ArcSin] = "asin"
ToMatlabaux[ArcCos] = "acos"
ToMatlabaux[ArcTan] = "atan"
ToMatlabaux[ArcCot] = "acot"
ToMatlabaux[ArcCsc] = "acsc"
ToMatlabaux[ArcSec] = "asec"
ToMatlabaux[Sinh] := "sinh"
ToMatlabaux[Cosh] := "cosh"
ToMatlabaux[Tanh] := "tanh"
ToMatlabaux[Coth] := "coth"
ToMatlabaux[Csch] := "csch"
ToMatlabaux[Sech] := "sech"
ToMatlabaux[ArcSinh] := "asinh"
ToMatlabaux[ArcCosh] := "acosh"
ToMatlabaux[ArcTanh] := "atanh"
ToMatlabaux[ArcCoth] := "acoth"
ToMatlabaux[ArcCsch] := "acsch"
ToMatlabaux[ArcSech] := "asech"
ToMatlabaux[Log] := "log"
ToMatlabaux[Exp] := "exp"
ToMatlabaux[MatrixExp] := "expm"
ToMatlabaux[Pi] := "pi"
ToMatlabaux[ProductLog] := "lambertw"
ToMatlabaux[E] := "exp(1)"
ToMatlabaux[True] := "1"
ToMatlabaux[False] := "0"
ToMatlabaux[e_Symbol] := ToString[e]



(*** Relational operators ****************************************************)

ToMatlabaux[e_ /; Head[e] === Equal] :=
    ToMatlabrelop[ argslist[e], "=="]
ToMatlabaux[e_ /; Head[e] === Unequal] :=
    ToMatlabrelop[ argslist[e], "~="]
ToMatlabaux[e_ /; Head[e] === Less] :=
    ToMatlabrelop[ argslist[e], "<"]
ToMatlabaux[e_ /; Head[e] === Greater] :=
    ToMatlabrelop[ argslist[e], ">"]
ToMatlabaux[e_ /; Head[e] === LessEqual] :=
    ToMatlabrelop[ argslist[e], "<="]
ToMatlabaux[e_ /; Head[e] === GreaterEqual] :=
    ToMatlabrelop[ argslist[e], ">="]
ToMatlabaux[e_ /; Head[e] === And] :=
    ToMatlabrelop[ argslist[e], "&"]
ToMatlabaux[e_ /; Head[e] === Or] :=
    ToMatlabrelop[ argslist[e], "|"]
ToMatlabaux[e_ /; Head[e] === Not] :=
    "~(" <> ToMatlabaux[e[[1]]] <> ")"

ToMatlabrelop[e_, o_] :=
    If[Length[e] === 1, 
        "(" <> ToMatlabaux[e[[1]]] <> ")",
        "(" <> ToMatlabaux[e[[1]]] <> ")" <> o <>
         ToMatlabrelop[ argslistdrop[e], o] ]

relopQ[e_] := MemberQ[{Equal, Unequal, Less, Greater, LessEqual,
    GreaterEqual, And, Or, Not}, Head[e]]



(*** Addition, multiplication and powers *************************************)

ToMatlabaux[e_ /; Head[e] === Plus] :=
    If[relopQ[e[[1]]],
        "(" <> ToMatlabaux[e[[1]]] <> ")",
        ToMatlabaux[e[[1]]] ] <>
    "+" <>
        If[Length[e] === 2,
            If[relopQ[e[[2]]],
                "(" <> ToMatlabaux[e[[2]]] <> ")",
                ToMatlabaux[e[[2]]] ],
            ToMatlabaux[ dropfirst[e] ]]

ToMatlabaux[e_ /; Head[e] === Times] :=
    If[Head[e[[1]]] === Plus,
        "(" <> ToMatlabaux[e[[1]]] <> ")",
        ToMatlabaux[e[[1]]] ] <>
    ".*" <>
        If[Length[e] === 2,
            If[Head[e[[2]]] === Plus,
                "(" <> ToMatlabaux[e[[2]]] <> ")",
                ToMatlabaux[e[[2]]] ],
            ToMatlabaux[ dropfirst[e] ]]

ToMatlabaux[e_ /; Head[e] === Power] :=
    If[Head[e[[1]]] === Plus || Head[e[[1]]] === Times || Head[e[[1]]] === Power,
        "(" <> ToMatlabaux[e[[1]]] <> ")",
        ToMatlabaux[e[[1]]] ] <>
    ".^" <>
        If[Length[e] === 2,
            If[Head[e[[2]]] === Plus || Head[e[[2]]] === Times || Head[e[[2]]] === Power,
                "(" <> ToMatlabaux[e[[2]]] <> ")",
                ToMatlabaux[e[[2]]] ],
            ToMatlabaux[ dropfirst[e] ]]



(*** Special cases of functions **********************************************)

ToMatlabaux[Rule[_,r_]] := ToMatlabaux[r]

ToMatlabaux[Log[10, z_]] := "log10(" <> ToMatlabaux[z] <> ")"
ToMatlabaux[Log[b_, z_]] :=
    "log(" <> ToMatlabaux[z] <> ")./log(" <> ToMatlabaux[b] <> ")"

ToMatlabaux[Power[e_, 1/2]] := "sqrt(" <> ToMatlabaux[e] <> ")"
ToMatlabaux[Power[E, z_]] := "exp(" <> ToMatlabaux[z] <> ")"

ToMatlabaux[If[test_, t_, f_]] :=
    Block[{teststr = ToMatlabaux[test]},
        "((" <> teststr <> ").*(" <> ToMatlabaux[t] <> ")+(~("
             <> teststr <> ")).*(" <> ToMatlabaux[f] <> "))"]

ToMatlabaux[e__ /; (Head[e] === Max || Head[e] == Min)] :=
    ToMatlabaux[Head[e]] <> "(" <>
        If[ Length[e] === 2,
            ToMatlabargs[e] <> ")",
            ToMatlabaux[e[[1]]] <> "," <> ToMatlabaux[dropfirst[e]] <> ")"]

ToMatlabaux[Colon[a_,b_]] :=
    "((" <> ToMatlabaux[a] <> "):(" <> ToMatlabaux[b] <> "))"
ToMatlabaux[Colon[a_,b_,c_]] :=
    "((" <> ToMatlabaux[a] <> "):(" <> ToMatlabaux[b] <> 
        "):(" <> ToMatlabaux[c] <> "))"



(*** General functions *******************************************************)

ToMatlabaux[e_] :=
    ToMatlabaux[Head[e]] <> "(" <>
        ToMatlabargs[ argslist[e] ] <> ")"

ToMatlabargs[e_] :=
    If[Length[e] === 1, 
        ToMatlabaux[e[[1]]],
        ToMatlabaux[e[[1]]] <> "," <>
            ToMatlabargs[ argslistdrop[e] ] ]



(*** Argument lists **********************************************************)

(*** argslist returns a List of the arguments ***)
argslist[e_] :=
    Block[{ARGSLISTINDEX}, Table[ e[[ARGSLISTINDEX]],
        {ARGSLISTINDEX, 1, Length[e]}]]

(*** argslistdrop returns a List of all arguments except the first one ***)
argslistdrop[e_] :=
    Block[{ARGSLISTINDEX}, Table[ e[[ARGSLISTINDEX]], 
        {ARGSLISTINDEX, 2, Length[e]}]]

(*** dropfirst is like argslistdrop but retains the original Head ***)
dropfirst[e_] :=
    e[[ Block[{i}, Table[i, {i,2,Length[e]}]] ]]



(*** Folding long lines ******************************************************)

MARGIN = 100
MARGINS = {}

SetMargin[m_] := (MARGINS = Prepend[MARGINS, MARGIN]; MARGIN = m; MARGINS)

RestoreMargin[] := 
    If[Length[MARGINS] > 0,
	MARGIN = MARGINS[[1]];
	MARGINS = Drop[MARGINS, 1]]		

foldlines[sSs_String] :=
    Block[{cut, sin=sSs, sout=""},
	While[StringLength[sin] >= MARGIN, 
	    cut = findcut[sin];
	    If[cut > 0,		
		sout = sout <> StringTake[sin,cut] <> " ...\n  ";
		sin = StringDrop[sin,cut],
		(* else *)
		sout = sout <> StringTake[sin,MARGIN];
		sin = StringDrop[sin,MARGIN]]];
	sout <> sin]

findcut[sSs_String] :=
    Block[{i=MARGIN}, 
        While[i > 0 &&
              !MemberQ[{";", ",", "(", ")", "+", "*", " "}, StringTake[sSs,{i}]],
            i--];
        i]

(* End[]

EndPackage[]
*)

