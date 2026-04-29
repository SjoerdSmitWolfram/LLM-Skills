(* ::Package:: *)

(* Wolfram Language Function Documentation Search Utilities *)
(* Provides:
TODO
*)

Clear["DocumentationSearchUtilities`*", "DocumentationSearchUtilities`Private`*"]

BeginPackage["DocumentationSearchUtilities`"];


DocuSearch::usage = "DocuSearch[query, \"Start\" -> i, \"Limit\" -> n] returns search results for a given query string. The options Start (default: 1) \
and Limit (default: 5) are used for pagination of results.";

DocPageSkeleton::usage = "DocPageSkeleton[uri] returns an association with summary data in a doc page referred to by a given URI string (such as \"ref/Plot\").
DocPageSkeleton[{uri_1, uri_2, ...}] returns an association where the keys are the URIs and the values are the summary results. URIs that were not \
found will be dropped."


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


DocuSearch /: Information[DocuSearch, "Comments"] = ToString @ StringForm[
	"DocuSearch[query] returns an association with the following keys: `1`. The key \"Matches\" returns a list of associations with keys determined by the value of the \"MetaData\" option. By default these keys are: `2`",
	{"Query", "ParsedQuery", "Start", "Limit", "SearchTime", "TotalMatches", "Suggestions", "Matches"},
	{"Title", "Type", "ShortenedSummary", "URI", "URL", "Description", "Context"}
];

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


uriToFileName[uri_String] := Replace[
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
uriToFileName[_] := $Failed;

DocPageSkeleton /: Information[DocPageSkeleton, "Comments"] = ToString @ StringForm[
	"DocPageSkeleton[uri] returns an association with the following possible keys (and potentially others), depending on the type of URI: `1`",
	{"Abstract", "Caption", "Context", "Description", "Dictionary",  "DisplayedCategory", "ExactTitle", "ExampleText", "Frequency", 
	"FunctionsSubsection", "Keywords", "Language", "LinkedSymbols", "Location", "MathCaption", "NormalizedTitle", "NotebookPackage", 
	"NotebookStatus", "NotebookType", "PacletName", "ReferredBy", "SeeAlso", "ShortNotations", "SnippetPlaintext", "Synonyms", 
	"TableText", "Text", "Title", "TokenizedNotebookType", "URL", "Usage"}
]

DocPageSkeleton[uri_] := Enclose @ Module[{
	input = uri,
	files,
	results,
	output
},
	ConfirmMatch[input, _String | {___String}, "Invalid URI specification"];
	files = Discard[FailureQ] @ AssociationMap[
		uriToFileName,
		Flatten[{input}]
	];
	output = If[ Length[files] === 0,
		files,
		results = ConfirmMatch[
			ds`Skeletonizer`Skeletonize[Values[files]],
			{___Association},
			"Internal error"
		];
		Join[
			AssociationThread[Keys[files], Missing["NotFound"]],
			AssociationThread[Lookup[results, "URI"], KeyDrop[results, "URI"]]
		]
	];
	If[ ListQ[input],
		output,
		First[output, Missing["NotFound"]]
	]
];


End[]

EndPackage[];