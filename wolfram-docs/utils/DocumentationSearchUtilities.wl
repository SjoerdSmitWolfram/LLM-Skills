(* ::Package:: *)

(* Wolfram Language Function Documentation Search Utilities *)
(* Provides:
TODO
*)

Clear["DocumentationSearchUtilities`*", "DocumentationSearchUtilities`Private`*"]

BeginPackage["DocumentationSearchUtilities`"];


DocuSearch::usage = "DocuSearch[query, \"Start\" -> i, \"Limit\" -> n] returns search results for a given query string. The options Start (default: 1) \
and Limit (default: 5) are used for pagination of results.";

DocPageSkeleton::usage = "DocPageSkeleton[uri] provides an overview of the data in a doc page referred to by a given URI string (such as \"ref/Plot\")."


Begin["`Private`"]

Needs["DocumentationSearch`" -> "ds`"]

urlToMarkDown[list_List] := urlToMarkDown /@ list;
urlToMarkDown[assoc_Association] /; StringQ[assoc["URL"]] := With[{
	url = urlToMarkDown @ assoc["URL"]
},
	Join[assoc, <|"URL" -> url|>]
];
urlToMarkDown[url_String] /; !StringEndsQ[url, ".en.md"] := StringDelete[url, ".html" ~~ EndOfString] <> ".en.md";
urlToMarkDown[expr_] := expr


Options[DocuSearch] = {
	"MetaData" -> {"Title", "Type", "ShortenedSummary", "URI", "URL", "Description", "Context"},
	"Start" -> 1, "Limit" -> 5
};

DocuSearch[q_String, opts : OptionsPattern[]] := Enclose @ Module[{
	headers = OptionValue["MetaData"],
	result
},
	result = ConfirmMatch[
		ds`SearchDocumentation[q,
			"MetaData" -> headers,
			"Start" -> OptionValue["Start"], "Limit" -> OptionValue["Limit"]
		],
		KeyValuePattern[{"Query" -> _, "Matches" -> _List}],
		"Unexpected return value for DocumentationSearch`SearchDocumentation"
	];
	MapAt[
		ConfirmMatch[
			If[ Length[#] > 0,
				urlToMarkDown @ FromTabular[Tabular[#, headers], "Rows"],
				{}
			],
			{___Association},
			"Unexpected search results"
		]&,
		Association @ result,
		Key["Matches"]
	]
];


uriToFileName[uri_] := Replace[
	Module[{nb},
		UsingFrontEnd @ WithCleanup[
			nb = NotebookOpen["paclet:" <> uri, Visible -> False]
			,
			If[ !FailureQ[nb] && MatchQ[nb, _NotebookObject],
				NotebookFileName[nb],
				nb
			]
			,
			NotebookClose[nb]
		]
	],
	Except[_?FileExistsQ] :> $Failed
];


DocPageSkeleton[uri_] := Enclose @ Module[{
	files = Discard[FailureQ] @ AssociationMap[
		uriToFileName,
		Flatten[{uri}]
	],
	results
},
	If[ Length[files] === 0,
		files,
		results = ConfirmMatch[
			ds`Skeletonizer`Skeletonize[Values[files]],
			{___Association}
		];
		AssociationThread[Lookup[results, "URI"], KeyDrop[results, "URI"]]
	]
];


End[]

EndPackage[];