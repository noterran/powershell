@ECHO OFF
ECHO Mapping V (Cdata01) and W (ncdata01) drives for Marcello by Tonny Roger Holm
cmd
echo y|NET USE W: /D >Nul: 2>&1
echo y|NET USE T: /D >Nul: 2>&1
 
IF EXIST \\Marcello.LAN\CriticalData-01\CData01 echo y|net use v: \\Marcello.LAN\CriticalData-01\CData01
IF EXIST "\\Marcello.LAN\CriticalData-01\CData01\Marcello driftsenter\Teams" echo y|net use t: "\\Marcello.LAN\CriticalData-01\CData01\Marcello driftsenter\Teams"
IF EXIST \\marcello.lan\noncriticaldata-01\NCData01 echo y|net use w: \\marcello.lan\noncriticaldata-01\NCData01
IF NOT EXIST V:\ IF EXIST \\10.5.19.25\cdata01 echo y|net use v: \\10.5.19.25\cdata01
IF NOT EXIST T:\ IF EXIST "\\10.5.19.25\cdata01\Marcello driftsenter\Teams" echo y|net use t: "\\10.5.19.25\cdata01\Marcello driftsenter\Teams"
IF NOT EXIST W:\ IF EXIST \\10.5.19.25\NCData01 echo y|net use w: \\10.5.19.25\NCData01