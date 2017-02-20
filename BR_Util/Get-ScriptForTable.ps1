function Get-ScriptForTable
{
    param (
        $server, 
        $dbname,
        $user,
        $password,
        $filter
    )

[System.reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo") | out-null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo")  | out-null

$conn = new-object "Microsoft.SqlServer.Management.Common.ServerConnection" 
$conn.ServerInstance = $server
$conn.LoginSecure = $false
$conn.Login = $user
$conn.Password = $password
$conn.ConnectAsUser = $false
$srv = New-Object "Microsoft.SqlServer.Management.Smo.Server" $conn

$Scripter = new-object ("Microsoft.SqlServer.Management.Smo.Scripter")
#$Scripter.Options.DriAll = $false
$Scripter.Options.NoCollation = $True
$Scripter.Options.NoFileGroup = $true
$scripter.Options.DriAll = $True
$Scripter.Options.IncludeIfNotExists = $False
$Scripter.Options.ExtendedProperties = $false
$Scripter.Server = $srv

$database = $srv.databases[$dbname]
$obj = $database.tables

$cnt = 1
$obj | % {

    if (! $filter -or  $_.Name -match $filter)
    {
        $lines = @()
        $header = "---------- {0, 3} {1, -30} ----------"  -f $cnt, $_.Name
        Write-Host $header 

        "/* ----------------- {0, 3} {1, -30} -----------------"  -f $cnt, $_.Name
        foreach( $i in $_.ExtendedProperties)
        {
            "{0}: {1}" -f $i.Name, $i.value
        }
        ""
        $colinfo = @{}
        foreach( $i in $_.columns)
        {
            $info = ""
            foreach ($ep in $i.ExtendedProperties)
            {
                if ($ep.value -match "`n")
                {
                    "----- Column: {0}  {1} -----" -f $i.name, $ep.name
                    $ep.value
                }
                else
                {
                    $info += "{0}:{1}  " -f $ep.name, $ep.value
                }
            }
            if ($info)
            {
                $colinfo[$i.name] =  $info
            }
        }
        ""
        "SELECT COUNT(*) FROM {0}" -f $_.Name
        "SELECT * FROM {0} ORDER BY 1" -f $_.Name
        "--------------------- {0, 3} {1, -30} ----------------- */" -f $cnt, $_.Name
        ""
        $raw = $Scripter.Script($_)
        #Write-host $raw
        $cont = 0
        $skip = $false 
        foreach ($line in $raw -split "\r\n")
        {
            if ($cont -gt 0)
            {
                if ($line -match "^\)WITH ")
                {
                    $line = ")"
                }
                $linebuf += ' ' + $line -replace " ASC", ""
                $cont--
                if ($cont -gt 0) { continue }
            }
            elseif ($line -match "^ CONSTRAINT ")
            {
                $cont = 3
                $linebuf = $line
                continue
            }
            elseif ($line -match "^UNIQUE ")
            {
                $cont = 3
                $linebuf = $line
                $skip = $true
                continue
            }
            elseif ($line -match "^ALTER TABLE.*WITH CHECK ")
            {
                $cont = 1
                $linebuf = "-- " + $line
                continue
            }
            elseif ($line -match "^ALTER TABLE.* CHECK ")
            {
                continue
            }
            else
            {
                $linebuf = $line
            }
            if ($linebuf -notmatch "^SET ")
            {
                if ($linebuf -match "^\)WITH ")
                {
                    $lines += ")"
                }
                elseif ($skip)
                {
                    $skip = $false
                }
                elseif ($linebuf -notmatch "^\s*$")
                {
                    $linebuf = $linebuf -replace "\]|\[", ""
                    $comment = $colinfo[($linebuf.Trim() -split " ")[0]]
                    if ($comment) { $comment = ' -- ' + $comment }
                    $lines += $linebuf + $comment
                }
            }
        }
        $lines += "go"
        $lines += ""
        $block = $lines -join "`r`n"
        $block
        $cnt++
        $used = $false
        foreach( $i in $_.Indexes)
        {
            $out = ''
            $raw = $Scripter.Script($i)
            #Write-host $raw
            foreach ($line in $raw -split "\r\n")
            {
                if ($line -match "^\)WITH ")
                {
                    $out += ")"
                }
                elseif ($line -match "^ALTER TABLE.* PRIMARY KEY")
                {
                    break
                }
                elseif ($line -match "^ALTER TABLE.* ADD UNIQUE")
                {
                    $out += $line -replace "\]|\[", "" -replace " NONCLUSTERED", "" 
                }
                elseif ($line -notmatch "^\s*$")
                {
                    $out += $line -replace "\]|\[", "" -replace "^\s*", "" `
                    -replace " ASC,", ", " -replace " ASC$", "" `
                    <#-replace "\bdbo\.\b", "" #> `
                    -replace " NONCLUSTERED", "" 
                }
                $used = $true
            }
            $block = "$out;`r`ngo`r`n"
            $out
        }
        if ($used)
        {
            "go"
        }
    }
} 
}