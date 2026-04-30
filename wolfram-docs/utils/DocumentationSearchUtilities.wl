(* Wolfram Language Function Documentation Search Utilities *)

(* 
Public function usage can be found between the BeginPackage[...] and Begin[...] lines

Function definition sections are delineated with comments that look like:

(* ================ fun Start ================ *)

*fun definitions*

(* ================ fun End ================ *)

*)


Clear["DocumentationSearchUtilities`*", "DocumentationSearchUtilities`Private`*"]

BeginPackage["DocumentationSearchUtilities`"];


DocuSearch::usage = "DocuSearch[query, \"Start\" -> i, \"Limit\" -> n] returns search results for a given query string. The options Start (default: 1) \
and Limit (default: 5) are used for pagination of results. \n\n" <> StringTemplate[
	"The returned association has the following keys: `1`. \n\nThe key \"Matches\" returns a list of associations with keys determined by the value of the \"MetaData\" option. By default these keys are: `2`"][
	{"Query", "ParsedQuery", "Start", "Limit", "SearchTime", "TotalMatches", "Suggestions", "Matches"},
	{"Title", "Type", "ShortenedSummary", "URI", "URL", "Description", "Context"}
];

DocPageSkeleton::usage = "DocPageSkeleton[uri] returns an association with summary data in a doc page referred to by a given URI string (such as \"ref/Plot\").
DocPageSkeleton[{uri_1, uri_2, ...}] returns an association where the keys are the URIs and the values are the summary results. URIs that were not \
found will be dropped. \n\n" <> StringTemplate[
	"The returned summary data has the following possible keys (and potentially others), depending on the type of URI:\n`1`"][
	{
		"Abstract", "Caption", "Context", "Description", "Dictionary",  "DisplayedCategory", "ExactTitle", "ExampleText", "Frequency", 
		"FunctionsSubsection", "Keywords", "Language", "LinkedSymbols", "Location", "MathCaption", "NormalizedTitle", "NotebookPackage", 
		"NotebookStatus", "NotebookType", "PacletName", "ReferredBy", "SeeAlso", "ShortNotations", "SnippetPlaintext", "Synonyms", 
		"TableText", "Text", "Title", "TokenizedNotebookType", "URL", "Usage"
	}
];


FetchAndCacheOnlineDocPage::usage = "FetchAndCacheOnlineDocPage[url] fetches the markdown version of a documentation page at a given URL. \
It if successful, it will locally cache the page and return the file name of the cache.
FetchAndCacheOnlineDocPage[url, forceQ] allows the user to specify if the re-caching should be forced. The default for forceQ is False."

OnlineDocsQuery::usage = "OnlineDocsQuery[url, elements] extracts specific elements from the online documentation at the requested URL.
Possible elements are:
Elements: A list of the possible elements that can be extracted. This is page-dependent.
YAML: A string with the YAML that can be found at the top of the file.
StructuredYAML: A Wolfram representation of the YAML front matter (i.e., an associations).
StructuredYAML -> Keys: The keys present in the YAML front matter.
StructuredYAML -> {key_1, key_2, ...}: Extract specific keys from the structured YAML.
FullText: The entire markdown text.
Sections: All the markdown section headers found in the file.
element -> \"Length\": The amount of data in a given element. For lists and associations, this returns the number of elements. For strings \
it returns the number of characters.
{el_1, el_2, ...}: Extract multiple elements. Returns an association with the requested elements."


Begin["`Private`"]

Needs["DocumentationSearch`" -> "ds`"]


(* ================ DocuSearch Start ================ *)

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
				FromTabular[Tabular[#, headers], "Rows"],
				{}
			],
			{___Association},
			"Unexpected search results"
		]&,
		Association @ result,
		Key["Matches"]
	]
];

(* ================ DocuSearch End ================ *)


(* ================ DocPageSkeleton Start ================ *)

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

(* ================ DocPageSkeleton End ================ *)



(* ================ FetchAndCacheOnlineDocPage Start ================ *)

$cacheDir = FileNameJoin[ParentDirectory @ DirectoryName[$InputFileName], "cache"];

FetchAndCacheOnlineDocPage[url_, forceQ : _ : False] := Enclose @ Module[{
	mdURL = Confirm @ urlToMarkDown[url],
	cacheFileName, cachedQ, mdString
},
	ConfirmAssert[StringQ[mdURL] && StringStartsQ[mdURL, "https://reference.wolfram.com"], "Not a valid URL"];
	cacheFileName = FileNameJoin[{
		$cacheDir,
		Splice @ FileNameSplit[StringDelete[mdURL, StartOfString ~~ Shortest[__] ~~ "/language/"]]
	}];
	cachedQ = FileExistsQ[cacheFileName] && !TrueQ[forceQ];
	If[ !TrueQ[cachedQ],
		mdString = Confirm[Import[mdURL, "String"], "Import failure"];
		ConfirmAssert[
			StringQ[mdString] && StringStartsQ[mdString, "---\ntitle:"]
		];
		Export[cacheFileName, mdString, "String"]
	];

	ConfirmBy[cacheFileName, FileExistsQ]
];

urlToMarkDown[url_String] /; !StringEndsQ[url, ".en.md"] := StringDelete[url, ".html" ~~ EndOfString] <> ".en.md";
urlToMarkDown[expr_] := expr;


(* ================ FetchAndCacheOnlineDocPage End ================ *)




(* ================ OnlineDocsQuery Start ================ *)

OnlineDocsQuery[url_] := OnlineDocsQuery[url, "Elements"];

OnlineDocsQuery[url_, "FullText"] := Replace[
	FetchAndCacheOnlineDocPage[url],
	s_String :> Import[s, "String"]
];

OnlineDocsQuery[url_, "YAML"] := Replace[
	OnlineDocsQuery[url, "FullText"],
	s_String :> First[StringCases[s, StartOfString ~~ "---" ~~ Shortest[__] ~~ "\n---", 1], Missing["NotFound"]]
];

OnlineDocsQuery[url_, "StructuredYAML"] := Replace[
	OnlineDocsQuery[url, "YAML"],
	s_String :> yamlToWL[s]
];


(* Additional OnlineDocsQuery implementations *)
OnlineDocsQuery[url_, "Elements"] := {
	"YAML", "StructuredYAML", "FullText", "Sections",
	"StructuredYAML" -> "Keys", 
	"StructuredYAML" -> {"key1", "key2"},
	"element" -> "Length",
	{"element1", "element2"}
};

OnlineDocsQuery[url_, "Sections"] := Replace[
	OnlineDocsQuery[url, "FullText"],
	s_String :> StringCases[s, RegularExpression["^#+\\s+(.+)$"], 1]
];

OnlineDocsQuery[url_, ("StructuredYAML" -> "Keys")] := Replace[
	OnlineDocsQuery[url, "StructuredYAML"],
	a_Association :> Keys[a]
];

OnlineDocsQuery[url_, ("StructuredYAML" -> keys_List)] := Replace[
	OnlineDocsQuery[url, "StructuredYAML"],
	a_Association :> KeyTake[a, keys]
];

OnlineDocsQuery[url_, (element_ -> "Length")] := Replace[
	OnlineDocsQuery[url, element],
	{
		s_String :> StringLength[s],
		l_List :> Length[l],
		a_Association :> Length[a],
		_ :> Missing["NotApplicable"]
	}
];

OnlineDocsQuery[url_, elements_List] := AssociationMap[
	OnlineDocsQuery[url, #]&,
	elements
];

(* ================ OnlineDocsQuery End ================ *)


(* ================ yamlToWL Start ================ *)

yamlToWL[s_String] := Enclose @ Module[{
	lines, cleanLines, parsed
},
	(* Remove YAML delimiters and split into lines *)
	lines = StringSplit[
		StringDelete[s, StartOfString ~~ "---" ~~ ("\n" | EndOfString) | "\n---" ~~ EndOfString], 
		"\n"
	];
	
	(* Remove empty lines and comments *)
	cleanLines = DeleteCases[lines, "" | Whitespace | _?(StringStartsQ[#, "#"]&)];
	
	(* Parse the YAML structure *)
	parsed = parseYAMLLines[cleanLines];
	
	ConfirmBy[parsed, AssociationQ, "YAML parsing failed"]
];

(* Helper function to parse YAML lines into Wolfram associations *)
parseYAMLLines[lines_List] := Module[{
	result = <||>, currentKey = None, currentValue = {}, inList = False, listIndent = 0
},
	Do[
		With[{line = lines[[i]]},
			Which[
				(* Key-value pair at root level *)
				StringMatchQ[line, RegularExpression["^[a-zA-Z_][a-zA-Z0-9_]*:\\s*(.*)$"]] && !StringStartsQ[line, " "],
				Module[{key, value},
					{key, value} = parseKeyValue[line];
					If[inList, 
						(* Finish previous list *)
						result[currentKey] = currentValue;
						inList = False;
						currentValue = {};
					];
					If[StringQ[value] && value != "",
						result[key] = value,
						(* Prepare for potential list *)
						currentKey = key;
						inList = True;
						currentValue = {};
					]
				],
				
				(* List item *)
				StringMatchQ[line, RegularExpression["^\\s*-\\s*(.*)$"]],
				Module[{indent, content},
					indent = StringLength[StringCases[line, StartOfString ~~ Whitespace, 1][[1]]];
					content = StringTrim[StringDelete[line, StartOfString ~~ Whitespace ~~ "-" ~~ Whitespace]];
					
					If[!inList,
						(* Start new list *)
						inList = True;
						listIndent = indent;
						currentValue = {};
					];
					
					If[indent == listIndent,
						(* Simple list item *)
						If[content != "",
							AppendTo[currentValue, content],
							(* Object list item starting *)
							AppendTo[currentValue, <||>]
						],
						(* Nested content - handle as key-value in last object *)
						If[Length[currentValue] > 0 && AssociationQ[Last[currentValue]],
							Module[{key, value},
								{key, value} = parseKeyValue[StringTrim[content]];
								currentValue[[-1]][key] = value;
							]
						]
					]
				],
				
				(* Nested key-value pairs (for objects in lists) *)
				StringStartsQ[line, " "] && StringContainsQ[line, ":"] && inList,
				Module[{key, value, trimmed},
					trimmed = StringTrim[line];
					{key, value} = parseKeyValue[trimmed];
					If[Length[currentValue] > 0 && AssociationQ[Last[currentValue]],
						currentValue[[-1]][key] = value,
						(* Start new object *)
						AppendTo[currentValue, <|key -> value|>]
					]
				]
			]
		],
		{i, Length[lines]}
	];
	
	(* Add final list if we were building one *)
	If[inList, result[currentKey] = currentValue];
	
	result
];

(* Helper to parse individual key-value pairs *)
parseKeyValue[line_String] := Module[{
	parts, key, value
},
	parts = StringSplit[line, ":", 2];
	key = StringTrim[First[parts]];
	value = If[Length[parts] > 1, 
		StringTrim[Last[parts]], 
		""
	];
	
	(* Clean up quoted strings *)
	value = StringReplace[value, {
		StartOfString ~~ "\"" ~~ content___ ~~ "\"" ~~ EndOfString :> content,
		StartOfString ~~ "'" ~~ content___ ~~ "'" ~~ EndOfString :> content
	}];
	
	{key, value}
];

(* ================ yamlToWL End ================ *)

End[]

EndPackage[];