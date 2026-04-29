(* ::Package:: *)

(* Wolfram Language Function Plumbing Utilities *)
(* Provides DefinitionString function for examining internal implementations *)

BeginPackage["WolframPlumbing`"];

DefinitionString::usage = "DefinitionString[sym] returns the definition of symbol sym with context aliases for readability. Removes ReadProtected attribute and shows internal implementation details.";

Begin["`Private`"]

(* Main function for extracting and formatting symbol definitions *)
SetAttributes[DefinitionString, HoldFirst];
DefinitionString[sym_Symbol]
DefinitionString[sym_Symbol] := Block[
	{
		$ContextPath, $Context, $ContextAliases, contexts, str, aliases,
		defs
	},
	Internal`InheritedBlock[{sym},
		sym;
		Needs["CodeFormatter`" -> None];
		ClearAttributes[sym, ReadProtected];
		$ContextPath = DeleteDuplicates @ {"System`", Context[sym]};
		$Context = Context[sym];
		$ContextAliases = <||>;
		str = CodeFormatter`CodeFormat @ ToString[Definition[sym], InputForm];
		defs = GeneralUtilities`Definitions[sym];
		contexts = ReverseSortBy[StringLength] @ DeleteCases[
			DeleteDuplicates @ Cases[
				GeneralUtilities`Definitions[sym],
				s_Symbol :> Context[s],
				{0, Infinity},
				Heads -> True
			],
			Alternatives @@ $ContextPath
		];
		aliases = MapIndexed[#1 -> "c" <> ToString[First[#2]] <> "`"&, contexts];
		StringJoin[
			"Context: ", $Context,
			"\n\nAliases:\n", StringRiffle[aliases, "\n"],
			"\n\nDefinition:\n", StringTrim @ StringReplace[str, aliases],
			If[ FreeQ[defs, GeneralUtilities`PackageScope`$KernelFunctionPlaceholder],
				"",
				"\n\n<<Hidden kernel definitions>>"
			]
		]
	]
];

End[]

EndPackage[];