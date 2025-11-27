#region define variables
$dir = "Omsorg"
$subdir = "Home"
$path = "\\uni-fil-002\uni_inf_01\$dir\$subdir"
$csv = ","

$filename = $dir + "_" + $subdir + ".txt"
$resultfilename = "ADresult_" + $filename
$comparedfilename = "tobedeleted_" + $filename
#endregion

#region remove old files
Remove-Item "h:\$filename" -force -ErrorAction SilentlyContinue
Remove-Item "h:\$resultfilename" -force -ErrorAction SilentlyContinue
Remove-Item "h:\$comparedfilename" -force -ErrorAction SilentlyContinue
#endregion

#region get list of folders
(Get-ChildItem -Path $path).Name >> "h:\$filename"

$samUsers = Get-Content "h:\$filename"
#endregion

#region compare lists to exclude users that exist in active directory
foreach ($user in $samUsers){
    (Get-ADUser $user).samAccountName >> "h:\$resultfilename"
    }

$resultlist = Get-Content "h:\$resultfilename"

$samUsers | Where-Object{$resultlist -notcontains $_} >> "h:\$comparedfilename"

$tobedeleted = Get-Content "h:\$comparedfilename"
#endregion

#region delete folders of users that are not in active directory
foreach ($user in $tobedeleted){
    $User_Home = $path + "\" + $user
    Remove-Item -recurse -force -Path "$User_Home" -erroraction silentlycontinue
	$date = Get-Date -Format "MM/dd/yyyy HH:mm"
    $tolog = "$date" + "$csv" + "$user" >> "h:\$log"
    }
#endregion