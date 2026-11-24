(* ::Package:: *)

(* =====================================================================
   3 x 3 grid of jittered strip plots
   Rows:    age group, gender, education
   Columns: took part before, knew the concept, willing to join
   Each dot is one respondent; hovering shows their community.

   Input:  the original survey export, saved as CSV
           (all columns are needed, so this does not use survey_clean.csv)
   Output: the grid, plus survey_grid.png in Downloads
   ===================================================================== *)

(* ---------- 1. LOAD THE ORIGINAL DATA (CSV) ---------- *)
ClearAll[raw, header, rows, col, val, file];

file = FileNameJoin[{$HomeDirectory, "Downloads", "biodiversity_data_final.csv"}];
If[! FileExistsQ[file], file = SystemDialogInput["FileOpen"]];

raw = Import[file, "CSV"];
header = Map[StringTrim[ToString[#]] &, First[raw]];
rows = Rest[raw];
Print["Respondents loaded: ", Length[rows]];

col[name_] := First@FirstPosition[header, name];
val[r_, name_] := ToLowerCase@StringTrim@ToString[r[[col[name]]]];

cleanName[c_] := Module[{s = StringTrim[ToString[c]]},
  If[MemberQ[{"", "nil"}, ToLowerCase[s]], "Not stated",
     StringRiffle[Capitalize /@ StringSplit[s], " "]]];

blue = RGBColor[0, 0.45, 0.70];
verm = RGBColor[0.84, 0.37, 0];


(* ---------- 2. WHAT GOES ON EACH AXIS ---------- *)
(* rows: {column name, values in order, tick labels, short name} *)
xVars = {
  {"AGE", {"21-40", "41-60", ">60"}, {"21-40", "41-60", "60+"}, "age"},
  {"GENDER", {"male", "female"}, {"Male", "Female"}, "gender"},
  {"LEVEL OF EDUCATION", {"none", "secondary", "tertiary"}, {"None", "Sec.", "Tert."}, "education"}};

(* columns: {column name, short name} *)
yVars = {
  {"PARTICIPATION IN BIODIVERSITY", "took part"},
  {"CONCEPT OF CITIZEN SCIENCE", "knew concept"},
  {"WILLINGNESS TO JOIN CITIZEN SCIENCE PROJECT", "willing"}};


(* ---------- 3. ONE SMALL PANEL ---------- *)
panel[{xName_, xOrder_, xLabels_, xShort_}, {yName_, yShort_}] := Module[
  {data, pts, pct},
  SeedRandom[7];

  data = Select[
    Map[{FirstPosition[xOrder, val[#, xName]], val[#, yName],
         cleanName[#[[col["COMMUNITY"]]]]} &, rows],
    MatchQ[#, {{_Integer}, "yes" | "no", _}] &];

  pts[ans_] := Map[
    Tooltip[{#[[1, 1]] + RandomReal[{-0.25, 0.25}],
             If[ans == "yes", 1, 0] + RandomReal[{-0.15, 0.15}]}, #[[3]]] &,
    Select[data, #[[2]] == ans &]];

  (* % yes above each group *)
  pct = Table[
    With[{tot = Count[data, {{i}, _, _}], yes = Count[data, {{i}, "yes", _}]},
      Style[Text[If[tot == 0, "", ToString[Round[100. yes/tot]] <> "%"], {i, 1.45}],
            9, GrayLevel[0.4]]],
    {i, Length[xOrder]}];

  ListPlot[{pts["yes"], pts["no"]},
    PlotStyle -> {Directive[blue, PointSize[0.025]], Directive[verm, PointSize[0.025]]},
    PlotLabel -> Style[Row[{xShort, " vs ", yShort}], 11],
    Frame -> {True, True, False, False},
    FrameTicks -> {
      {{{0, "No", 0}, {1, "Yes", 0}}, None},
      {MapIndexed[{First[#2], #1, 0} &, xLabels], None}},
    PlotRange -> {{0.5, Length[xOrder] + 0.5}, {-0.5, 1.6}},
    LabelStyle -> 9,
    Epilog -> pct,
    Axes -> False,
    AspectRatio -> 0.8,
    ImageSize -> 230]
];


(* ---------- 4. THE 3 x 3 GRID ---------- *)
grid = Grid[Table[panel[xVars[[m]], yVars[[n]]], {m, 1, 3}, {n, 1, 3}],
  Frame -> All, Spacings -> {1, 1}]


(* ---------- 5. SAVE AS IMAGE ---------- *)
Export[FileNameJoin[{$HomeDirectory, "Downloads", "survey_grid.png"}], Magnify[grid, 2]];
