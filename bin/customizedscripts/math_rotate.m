original = Import[ToString[file],"Table"];
Print["Original coordinate:\n",TableForm[original]];
Nrow[matrix_] := Dimensions[matrix][[1]];
newcoord = Table[0,{i,Nrow[original]},{j,4}];
atom = 1; x = 2; y = 3 ; z = 4;
xc = (original[[1,x]]+original[[2,x]])/2;
yc = (original[[1,y]]+original[[2,y]])/2;
\[Phi] = ArcTan[yc/xc]; If[\[Phi]<0,\[Phi]+=Pi]; If[y0<0,\[Phi]+=Pi];
Print["New axis defined by: (",xc,", ",yc")"];
rotate[x1_,y1_]:=Module[{},
	\[Theta]1 = ArcTan[y1/x1]; If[\[Theta]1<0,\[Theta]1+=Pi];If[y1<0,\[Theta]1+=Pi];
	\[Theta]2 = \[Theta]1 - \[Phi];
	r = Sqrt[x1^2 + y1^2];
	x2 = r*Cos[\[Theta]2];
	y2 = r*Sin[\[Theta]2];
	Print[original[[i,atom]],": (",x1,", ",y1,") -- t1=",\[Theta]1,", t2=",\[Theta]2," --> (",x2,", ",y2,")"];
	newcoord[[i,atom]]=original[[i,atom]];
	newcoord[[i,x]]=x2;
	newcoord[[i,y]]=y2;
	newcoord[[i,z]]=original[[i,z]];
];
For[i=1,i<=Nrow[original],i++,
	rotate[original[[i,x]],original[[i,y]]];
];
Export[ToString[file]<>".rotated",newcoord,"Table"];
Exit[]
