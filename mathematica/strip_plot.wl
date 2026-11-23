(* ::Package:: *)

(* =====================================================================
   Jittered strip plot: willingness to join a citizen science project,
   by age group. Hovering over a dot shows the respondent's community.

   Input:  survey_clean.csv, exported from SQLite after running
           sql/clean_survey.sql
   Output: the chart, plus figures/willingness.png
   ===================================================================== *)

(* ---------- 1. LOAD THE CLEANED DATA ---------- *)
file = FileNameJoin[{$HomeDirectory, "Downloads", "survey_clean.csv"}];
If[! FileExistsQ[file], file = SystemDialogInput["FileOpen"]];

clean = Rest@Import[file];          (* Rest drops the header row *)
Print["Rows loaded: ", Length[clean]];

(* columns: 1 respondent_id | 2 age_group | 3 age_order |
            4 willingness   | 5 willing_flag | 6 community *)


(* ---------- 2. JITTERED POINTS WITH TOOLTIPS ---------- *)
SeedRandom[7];   (* same jitter every run *)

pt[r_] := Tooltip[
  {r[[3]] + RandomReal[{-0.25, 0.25}],      (* x: age group + jitter   *)
   r[[5]] + RandomReal[{-0.12, 0.12}]},     (* y: yes=1 / no=0 + jitter *)
  r[[6]]];                                  (* tooltip: community       *)

yesPts = pt /@ Select[clean, #[[5]] == 1 &];
noPts  = pt /@ Select[clean, #[[5]] == 0 &];


(* ---------- 3. "x of y said yes" LABELS ---------- *)
labels = Table[
  Style[Text[ToString[Count[clean, {_, _, i, _, 1, _}]] <> " of " <>
             ToString[Count[clean, {_, _, i, __}]] <> " said yes", {i, 1.35}],
        12, GrayLevel[0.4]], {i, 3}];


(* ---------- 4. THE CHART ---------- *)
chart = ListPlot[{yesPts, noPts},
  PlotStyle -> {Directive[RGBColor[0, 0.45, 0.70], PointSize[0.018]],    (* blue: yes       *)
                Directive[RGBColor[0.84, 0.37, 0], PointSize[0.018]]},   (* vermillion: no  *)
  Frame -> {True, True, False, False},
  FrameTicks -> {
    {{{0, "No", 0}, {1, "Yes", 0}}, None},                                (* left, right  *)
    {{{1, "21-40", 0}, {2, "41-60", 0}, {3, "Over 60", 0}}, None}},       (* bottom, top  *)
  FrameLabel -> {"Age group", "Willing to join?"},
  PlotRange -> {{0.5, 3.5}, {-0.4, 1.5}},
  LabelStyle -> 12,
  PlotLabel -> Style["56 of 57 respondents are willing to join a citizen science project", 15],
  Epilog -> labels,
  Axes -> False,
  ImagePadding -> {{60, 20}, {50, 40}},
  ImageSize -> Large]


(* ---------- 5. SAVE AS IMAGE ---------- *)
Export[FileNameJoin[{$HomeDirectory, "Downloads", "willingness.png"}], Magnify[chart, 2]];
