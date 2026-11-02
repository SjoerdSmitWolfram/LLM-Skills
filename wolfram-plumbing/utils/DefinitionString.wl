(* ::Package:: *)

(* Wolfram Language Function Plumbing Utilities *)
(* Provides DefinitionString function for examining internal implementations *)

BeginPackage["WolframPlumbing`"];

DefinitionString::usage = "DefinitionString[sym] returns the full definition of sym (including ReadProtected internals) as formatted, \
context-aliased text. DefinitionString[\"ctx`name\"] accepts a symbol name; DefinitionString[{\"name1\", \"name2\", ...}] \
concatenates several. Option \"LineWidth\" (default 120) controls code wrapping.";

Begin["`Private`"];

$aliasMinLength = 20; (* contexts shorter than this are printed in full: Internal`, Developer`, System`Private`, ... *)

(* Contexts of all symbols in a held expression, without evaluating anything. Note that _Symbol alone would also
   match unevaluated Symbol["name"] expressions, so atomicity is checked on the unevaluated match. *)
heldContexts[expr_] := Cases[
	expr,
	s_Symbol /; AtomQ[Unevaluated[s]] :> Context[Unevaluated[s]],
	{0, Infinity},
	Heads -> True
];

contextRegex[ctx_String] := StringReplace[ctx, c : Characters["\\^$.|?*+()[]{}"] :> "\\" <> c];

formatCode[str_String, width_] := With[{res = Quiet @ CodeFormatter`CodeFormat[str, "LineWidth" -> width]},
	If[StringQ[res], res, str]
];

Options[DefinitionString] = {"LineWidth" -> 120};
SetAttributes[DefinitionString, HoldFirst];

DefinitionString[name_String, opts : OptionsPattern[]] := Replace[
	Quiet @ ToExpression[name, InputForm, Hold],
	{
		Hold[s_Symbol] :> DefinitionString[s, opts],
		_ :> "Invalid symbol name: " <> name
	}
];

DefinitionString[names : {__String}, opts : OptionsPattern[]] := StringRiffle[
	Map[
		"==================== " <> # <> "\n" <> DefinitionString[#, opts]&,
		names
	],
	"\n\n"
];

DefinitionString[sym_Symbol, opts : OptionsPattern[]] := (
	(* Touching the symbol triggers autoloading; done outside the InheritedBlock so the loaded definitions persist *)
	Quiet[sym];
	Needs["CodeFormatter`" -> None];
	If[MemberQ[Attributes[sym], Locked],
		(* Locked symbols cannot be blocked, but their attributes cannot be changed either, so nothing needs restoring *)
		iDefinitionString[sym, OptionValue["LineWidth"]],
		Internal`InheritedBlock[{sym},
			Quiet @ ClearAttributes[sym, ReadProtected];
			iDefinitionString[sym, OptionValue["LineWidth"]]
		]
	]
);

SetAttributes[iDefinitionString, HoldFirst];

iDefinitionString[sym_Symbol, width_] :=
	Block[{$ContextPath = {"System`"}, $Context = "System`", $ContextAliases = <||>},
		Module[{fullName, defs, ctxCounts, mainCtx, aliased, aliases, str, notes = {}},
			fullName = Context[sym] <> SymbolName[Unevaluated[sym]];
			If[MemberQ[Attributes[sym], ReadProtected],
				AppendTo[notes, "Symbol is Locked and ReadProtected; its definition cannot be shown."]
			];
			defs = GeneralUtilities`Definitions[sym];
			If[!FreeQ[defs, System`Dump`AutoLoad],
				AppendTo[notes, "Definition is still an autoload stub; call the function once with simple arguments and retry."]
			];
			If[!FreeQ[defs, GeneralUtilities`PackageScope`$KernelFunctionPlaceholder],
				AppendTo[notes, "Some definitions are implemented in the kernel (C code) and are not shown."]
			];
			ctxCounts = KeyDrop[
				Counts @ heldContexts @ Replace[defs, GeneralUtilities`PackageScope`$KernelFunctionPlaceholder -> Null, {0, Infinity}],
				"System`"
			];
			(* Print the most frequently used non-System` context bare: that is usually the implementation's private context *)
			mainCtx = If[ctxCounts === <||>,
				Context[sym],
				First @ Keys @ TakeLargest[KeySort @ ctxCounts, 1]
			];
			$Context = mainCtx;
			aliased = Select[
				Keys @ ReverseSort @ KeyDrop[ctxCounts, mainCtx],
				StringLength[#] >= $aliasMinLength&
			];
			aliases = MapIndexed["c" <> ToString[First[#2]] <> "`" -> #1&, aliased];
			str = ToString[Definition[sym], InputForm];
			(* Longest context first, and only at the start of a symbol name, so that e.g. "Dataset`" does not
			   clobber the second segment of "Dataset`Dataset`PackagePrivate`" *)
			str = StringReplace[
				str,
				Map[
					RegularExpression["(?<![\\w`$])" <> contextRegex[#[[2]]]] -> #[[1]]&,
					ReverseSortBy[aliases, StringLength @* Last]
				]
			];
			str = formatCode[StringTrim[str], width];
			If[str === "" || str === "Null",
				str = "(no definitions)"
			];
			StringJoin[
				"Symbol: ", fullName,
				"\nPrinted without context: System`", If[mainCtx === "System`", "", " and " <> mainCtx],
				"\nOther contexts are printed in full or with these aliases: ",
				If[aliases === {}, "none", StringRiffle[#1 <> " = " <> #2& @@@ aliases, ", "]],
				If[notes === {}, "", "\nNotes: " <> StringRiffle[notes, " "]],
				"\n\n",
				str
			]
		]
	];

End[];

EndPackage[];
