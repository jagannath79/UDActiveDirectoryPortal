function Invoke-Sqlcmd2 {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [string]$ServerInstance,
        [Parameter(Position = 1, Mandatory = $false)]
        [string]$Database,
        [Parameter(Position = 2, Mandatory = $false)]
        [string]$Query,
        [Parameter(Position = 3, Mandatory = $false)]
        [string]$Username,
        [Parameter(Position = 4, Mandatory = $false)]
        [string]$Password,
        [Parameter(Position = 5, Mandatory = $false)]
        [Int32]$QueryTimeout = 600,
        [Parameter(Position = 6, Mandatory = $false)]
        [Int32]$ConnectionTimeout = 15,
        [Parameter(Position = 7, Mandatory = $false)]
        [ValidateScript( { test-path $_ })]
        [string]$InputFile,
        [Parameter(Position = 8, Mandatory = $false)]
        [ValidateSet("DataSet", "DataTable", "DataRow")]
        [string]$As = "DataRow"
    )

    if ($InputFile) {
        $filePath = $(resolve-path $InputFile).path
        $Query = [System.IO.File]::ReadAllText("$filePath")
    }

    $conn = new-object System.Data.SqlClient.SQLConnection

    if ($Username)
    { $ConnectionString = "Server={0};Database={1};User ID={2};Password={3};Trusted_Connection=False;Connect Timeout={4}" -f $ServerInstance, $Database, $Username, $Password, $ConnectionTimeout }
    else
    { $ConnectionString = "Server={0};Database={1};Integrated Security=True;Connect Timeout={2}" -f $ServerInstance, $Database, $ConnectionTimeout }

    $conn.ConnectionString = $ConnectionString

    #Following EventHandler is used for PRINT and RAISERROR T-SQL statements. Executed when -Verbose parameter specified by caller
    if ($PSBoundParameters.Verbose) {
        $conn.FireInfoMessageEventOnUserErrors = $true
        $handler = [System.Data.SqlClient.SqlInfoMessageEventHandler] { Write-Verbose "$($_)" }
        $conn.add_InfoMessage($handler)
    }

    $conn.Open()
    $cmd = new-object system.Data.SqlClient.SqlCommand($Query, $conn)
    $cmd.CommandTimeout = $QueryTimeout
    $ds = New-Object system.Data.DataSet
    $da = New-Object system.Data.SqlClient.SqlDataAdapter($cmd)
    [void]$da.fill($ds)
    $conn.Close()
    switch ($As) {
        'DataSet' { Write-Output ($ds) }
        'DataTable' { Write-Output ($ds.Tables) }
        'DataRow' { Write-Output ($ds.Tables[0]) }
    }

}

Import-Module UniversalDashboard

$AuthenticationMethod = New-UDAuthenticationMethod -Endpoint {
    param([PSCredential]$Credentials)

    if ($Credentials.UserName -eq "Admin" -and $Credentials.GetNetworkCredential().Password -eq "Test") {
        New-UDAuthenticationResult -Success -UserName "Adam"
    }

    New-UDAuthenticationResult -ErrorMessage "You aren't Admin!!!"

    
}

$LoginPage = New-UDLoginPage -AuthenticationMethod $AuthenticationMethod

$hompage = New-UDPage -Name "Home" -Content {

New-UDCard -Title 'Home Page' -Content {
    New-UDParagraph -Text 'Welcome to Active Directory Portal'
} 

}

$Page1 = New-UDPage -Name "ADUsers" -Content {

New-UDTabContainer -Tabs {
    New-UDTab -Text "Search By Network ID" -Content {
        New-UDInput -Title "Search User By Network ID" -Endpoint {
        param(
            
            [Parameter(Mandatory)]
            [string]$NetworkID
        )

        New-UDInputAction -Content {
        New-UdGrid -Title "User Details of $($NetworkID)" -Headers @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "AccountExpirationDate", "Description", "Mail", "Title", "Notes", "EmployeeID", "LastLogonDate", "Manager") -Properties @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "AccountExpirationDate", "Description", "mail", "Title", "info", "EmployeeID", "LastLogonDate","Manager") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADUser -Filter {SamAccountName -like $NetworkID} -Properties * | Select DisplayName,SamAccountName,Enabled,ExtensionAttribute2,AccountExpirationDate,Description,mail,Title,info,EmployeeID,LastLogonDate,@{N='Manager';E={(Get-ADUser $_.Manager).Name}} | Out-UDGridData

       }

             
        New-UdGrid -Title "Group Memberships of $($NetworkID)" -Headers @("name", "GroupCategory", "objectClass") -Properties @("name", "GroupCategory", "objectClass") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADPrincipalGroupMembership $NetworkID | Select name,GroupCategory,objectClass | Out-UDGridData

       }

       New-UdGrid -Title "ExtAttributes of $($NetworkID)" -Headers @("DisplayName", "SamAccountName", "extensionAttribute2", "extensionAttribute5", "msDS-cloudExtensionAttribute2") -Properties @("DisplayName", "SamAccountName", "extensionAttribute2", "extensionAttribute5", "msDS-cloudExtensionAttribute2") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADUser -Filter {SamAccountName -like $NetworkID} -Properties * | Select DisplayName,SamAccountName,extensionAttribute2,extensionAttribute5,msDS-cloudExtensionAttribute2 | Out-UDGridData
       }

       

       New-UDGrid -Id "mCalls" -Title "Evavi Access of $($NetworkID)" -Headers @("User_ID", "Display_Name", "Disabled", "Role") -Properties @("User_ID", "Display_Name", "Disabled", "Role")  -PageSize 10  -Endpoint {
                $qMyCalls = @"
            SELECT User_ID
                  ,Display_Name
                  ,Disabled
                  ,Role
                  
              FROM [ADAutomation].[dbo].[Evavi_Data] 
               where User_ID like '$($NetworkID)'
            
"@
                $CallData = Invoke-Sqlcmd2 -ServerInstance "localhost" -Database "ADAutomation" -Query $qMyCalls
                $CallData | Select-Object "User_ID", "Display_Name", "Disabled", "Role" | Out-UDGridData
            } -AutoRefresh -RefreshInterval 20



            New-UDGrid -Id "mCalls1" -Title "Provia Access of $($NetworkID)" -Headers @("OPR", "FACILITY", "OPR_NAME", "EMPLOYEE_ID","USER_GRP","DEF_EQ_TYPE","DEF_STATION") -Properties @("OPR", "FACILITY", "OPR_NAME", "EMPLOYEE_ID", "USER_GRP", "DEF_EQ_TYPE", "DEF_STATION")  -PageSize 10  -Endpoint {
                $qMyCalls1 = @"
            SELECT OPR
                  ,FACILITY
                  ,OPR_NAME
                  ,EMPLOYEE_ID
                  ,USER_GRP
                  ,DEF_EQ_TYPE
                  ,DEF_STATION
                  
              FROM [ADAutomation].[dbo].[Provia_Legacy_Data] 
               where OPR like '$($NetworkID)'
            
"@
                $CallData = Invoke-Sqlcmd2 -ServerInstance "localhost" -Database "ADAutomation" -Query $qMyCalls1
                $CallData | Select-Object "OPR", "FACILITY", "OPR_NAME", "EMPLOYEE_ID", "USER_GRP", "DEF_EQ_TYPE", "DEF_STATION" | Out-UDGridData
            } -AutoRefresh -RefreshInterval 20




       New-UdGrid -Title "DirectReports of $($NetworkID)" -Headers @("SamAccountName", "UserPrincipalName", "DisplayName", "Title", "Manager") -Properties @("SamAccountName", "UserPrincipalName", "DisplayName", "Title", "Manager") -AutoRefresh -RefreshInterval 60 -Endpoint {
       $result = @()
       $UserAccount = Get-ADUser $NetworkID -Properties DirectReports, DisplayName
       $UserAccount | select -ExpandProperty DirectReports | ForEach-Object {
       $User = Get-ADUser $_ -Properties DirectReports, DisplayName, Title, EmployeeID
       if ($null -ne $User.EmployeeID) {
       if (-not $NoRecurse) {
       }
       $hItemDetails = [PSCustomObject]@{
                    SamAccountName     = $User.SamAccountName
                    UserPrincipalName  = $User.UserPrincipalName
                    DisplayName        = $User.DisplayName
                    Title              = $user.Title
                    Manager            = $UserAccount.DisplayName
        }

        } 
        $result += $hItemDetails
        
        }
        $result | Out-UDGridData
        
        }
        
       #Get-ADPrincipalGroupMembership $NetworkID | Select name,GroupCategory,objectClass | Out-UDGridData

       
       


       
       New-UDButton -Text "Back" -OnClick {
       New-UDInputAction -RedirectUrl "/ADUsers"
       }

       
}
} -Validate
    }
    New-UDTab -Text "Search By FirstName" -Content {
        New-UDInput -Title "Search User By FirstName" -Endpoint {
        param(
            
            [Parameter(Mandatory)]
            [string]$FirstName
        )

        New-UDInputAction -Content {
        New-UdGrid -Title "User Details of $($FirstName)" -Headers @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "AccountExpirationDate", "Description", "Mail", "Notes", "EmployeeID", "LastLogonDate", "Manager", "Title") -Properties @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "AccountExpirationDate", "Description", "mail", "info", "EmployeeID", "LastLogonDate","Manager", "Title") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADUser -Filter {Givenname -like $FirstName} -Properties * | Select DisplayName,SamAccountName,Enabled,ExtensionAttribute2,AccountExpirationDate,Description,mail,info,EmployeeID,LastLogonDate,@{N='Manager';E={(Get-ADUser $_.Manager).Name}},Title | Out-UDGridData

       }
    }
} -Validate
}
New-UDTab -Text "Search By LastName" -Content {
       New-UDInput -Title "Search User By LastName" -Endpoint {
        param(
            
            [Parameter(Mandatory)]
            [string]$LastName
        )

        New-UDInputAction -Content {
        New-UdGrid -Title "User Details of $($LastName)" -Headers @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "AccountExpirationDate", "Description", "Mail", "Notes", "EmployeeID", "LastLogonDate", "Manager", "Title") -Properties @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "AccountExpirationDate", "Description", "mail", "info", "EmployeeID", "LastLogonDate","Manager", "Title") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADUser -Filter {Surname -like $LastName} -Properties * | Select DisplayName,SamAccountName,Enabled,ExtensionAttribute2,AccountExpirationDate,Description,mail,info,EmployeeID,LastLogonDate,@{N='Manager';E={(Get-ADUser $_.Manager).Name}},Title | Out-UDGridData
       
       }
    }

} -Validate
}
New-UDTab -Text "Search By EmployeeID" -Content {
        New-UDInput -Title "Search User By EmployeeID" -Endpoint {
        param(
            
            [Parameter(Mandatory)]
            [string]$EmployeeID
        )

        New-UDInputAction -Content {
        New-UdGrid -Title "User Details of $($EmployeeID)" -Headers @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "AccountExpirationDate", "Description", "Mail", "Notes", "EmployeeID", "LastLogonDate", "Manager", "Title") -Properties @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "AccountExpirationDate", "Description", "mail", "info", "EmployeeID", "LastLogonDate","Manager", "Title") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADUser -Filter {EmployeeID -like $EmployeeID} -Properties * | Select DisplayName,SamAccountName,Enabled,ExtensionAttribute2,AccountExpirationDate,Description,mail,info,EmployeeID,LastLogonDate,@{N='Manager';E={(Get-ADUser $_.Manager).Name}},Title | Out-UDGridData

       }
    }
    } -Validate
}}

}


$Page2 = New-UDPage -Name "ADGroups" -Content {
New-UDTabContainer -Tabs {
New-UDTab -Text "Security Group Membership" -Content {

 New-UDInput -Title "Enter Group Name" -Endpoint {
        param(
            
            [Parameter(Mandatory)]
            [string]$GroupName
        )        

        New-UDInputAction -Content {
        
        New-UdGrid -Title "Group Membership Details of $($GroupName)" -Headers @("GroupName", "Name", "SamAccountName", "DisplayName", "Enabled", "Type", "Nesting", "CrossForest", "ParentGroup", "ParentGroupDomain") -Properties ("GroupName", "Name", "SamAccountName", "DisplayName", "Enabled", "Type", "Nesting", "CrossForest", "ParentGroup", "ParentGroupDomain") -AutoRefresh -RefreshInterval 60 -Endpoint {
        $result = @()
       $groupdetails = Get-WinADGroupMember -Group $GroupName
       foreach ($info in $groupdetails)
       {
       $hItemDetails = [PSCustomObject]@{
       GroupName = $info.GroupName
       Name = $info.Name
       SamAccountName = $info.SamAccountName
       DisplayName = $info.DisplayName
       Enabled = $info.Enabled
       Type = $info.Type
       Nesting = $info.Nesting
       CrossForest = $info.CrossForest
       ParentGroup = $info.ParentGroup
       ParentGroupDomain = $info.ParentGroupDomain
}
$result += $hItemDetails
}
$result | Out-UDGridData
}

}


}}

}
}

$Page3 = New-UDPage -Name "Reports" -Content {
New-UDTabContainer -Tabs {
New-UDTab -Text "Accounts in DisabledTerms OU" -Content {
        New-UdGrid -Title "Accounts in DisabledTerms OU" -Headers @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "Mail", "Description", "EmployeeID", "Manager") -Properties @("DisplayName", "SamAccountName", "Enabled", "ExtensionAttribute2", "mail", "Description", "EmployeeID", "Manager") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADUser -Filter * -SearchBase "OU=DisabledTerms,OU=ScriptTest,DC=virtulux,DC=com" -Properties * | Select DisplayName,SamAccountName,Enabled,ExtensionAttribute2,mail,Description,EmployeeID,@{N='Manager';E={(Get-ADUser $_.Manager).Name}} | Out-UDGridData
    }
}
New-UDTab -Text "No EmployeeID Tagged for Associate" -Content {
        New-UdGrid -Title "No EmployeeID Tagged for Associate" -Headers @("DisplayName", "ExtensionAttribute2", "SamAccountName", "Enabled", "EmployeeID") -Properties @("DisplayName", "ExtensionAttribute2", "SamAccountName", "Enabled", "EmployeeID") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADUser -Filter {(EmployeeID -notlike '*') -AND (extensionAttribute2 -like 'Associate')} -Properties DisplayName,ExtensionAttribute2,SamAccountName,Enabled,EmployeeID | Where-Object {$_.DistinguishedName -NotLike "*OU=WW Templates,OU=ScriptTest,DC=virtulux,DC=com"} | select DisplayName,ExtensionAttribute2,SamAccountName,Enabled,EmployeeID | Out-UDGridData
    }
}
New-UDTab -Text "No EmployeeID Tagged for Non Associate" -Content {
        New-UdGrid -Title "No EmployeeID Tagged for Associate" -Headers @("DisplayName", "ExtensionAttribute2", "SamAccountName", "Enabled", "Country", "EmployeeID") -Properties @("DisplayName", "ExtensionAttribute2", "SamAccountName", "Enabled", "co", "EmployeeID") -AutoRefresh -RefreshInterval 60 -Endpoint {
       Get-ADUser -Filter {(EmployeeID -notlike '*') -AND (extensionAttribute2 -like 'Non Associate')} -Properties DisplayName,ExtensionAttribute2,SamAccountName,Enabled,co,EmployeeID | Where-Object {$_.DistinguishedName -NotLike "*OU=WW Templates,OU=ScriptTest,DC=virtulux,DC=com"} | select DisplayName,ExtensionAttribute2,SamAccountName,Enabled,co,EmployeeID | Out-UDGridData
    }
}
New-UDTab -Text "Expired Accounts Last 7 Days" -Content {
  New-UdGrid -Title "Expired Accounts Last 7 Days" -Headers @("DisplayName", "SamAccountName", "EmployeeID", "Manager", "ExtensionAttribute2", "pwdLastSet", "DistinguishedName", "AccountExpirationDate", "Enabled", "emailaddress") -Properties @("DisplayName", "SamAccountName", "EmployeeID", "Manager", "ExtensionAttribute2", "pwdLastSet", "DistinguishedName", "AccountExpirationDate", "Enabled", "emailaddress") -AutoRefresh -RefreshInterval 60 -Endpoint {
       $CurrentDate = Get-Date
       $Before14Days = $CurrentDate.AddDays(-6)
       $d1 = $Before14Days.Day
       $d2 = $Before14Days.Month
       $d3 = $Before14Days.Year
       $dateconcat = "$($d2)/$($d1)/$($d3)"
       Get-ADUser -Filter * -Properties DisplayName, SamAccountName, EmployeeID, Manager, ExtensionAttribute2, pwdLastSet, DistinguishedName, AccountExpirationDate, Enabled, emailaddress | Where-Object {$_.AccountExpirationDate -eq $dateconcat -AND $_.DistinguishedName -notlike "*OU=DisabledTerms*" -AND $_.EmployeeID -notlike "*INGMW*"} | select DisplayName, SamAccountName, EmployeeID, @{N='Manager';E={(Get-ADUser $_.Manager).Name}}, ExtensionAttribute2, @{N='pwdLastSet'; E={[DateTime]::FromFileTime($_.pwdLastSet)}}, DistinguishedName, AccountExpirationDate, Enabled, emailaddress | Out-UDGridData
} 
}


} 


}
$OnBoarding = New-UDPage -Name "ADOnBoarding" -Content {

New-UDCard -Title 'AD OnBoarding Accounts' -Content {
    New-UDInput -Title "Create new user" -Endpoint {
        param(
            
            [Parameter(Mandatory)]
            [string]$EmployeeID,
            [Parameter(Mandatory)]
            [string]$FirstName,
            [Parameter(Mandatory)]
            [string]$LastName,
            [Parameter(Mandatory)]
            [string]$TicketNo,
            [Parameter(Mandatory)]
            [ValidateSet("IM Associate", "Non IM Associate")]
            [string]$UserType,
            [Parameter(Mandatory)]
            [ValidateSet("IM Corporate")]
            [string]$Domain,
            [Parameter(Mandatory)]
            [ValidateSet("New User")]
            [string]$RequestType,
            [Parameter(Mandatory)]
            [string]$Region,
            [Parameter(Mandatory)]
            [string]$Country,
            [Parameter(Mandatory)]
            [string]$Department,
            [Parameter(Mandatory)]
            [string]$Location,
            [Parameter(Mandatory)]
            [ValidateSet("Yes", "No")]
            [string]$NetworkIdRequired,
            [Parameter(Mandatory)]
            [ValidateSet("Yes", "No")]
            [string]$OutlookRequired,
            [Parameter(Mandatory)]
            [string]$ManagerNetworkId,
            [string]$Title
            
        )

        $password = [System.Web.Security.Membership]::GeneratePassword((Get-Random -Minimum 20 -Maximum 32), 3)
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        $name = $LastName + ", " + $FirstName
        [string]$upn = ($FirstName + "." + $LastName + "@virtulux.com")
        [string]$notes = $TicketNo + " - " + "NH"
                 

        if($NetworkIdRequired -eq "No")
        {
             #$message = "User $($empidvalidation.displayname) already Exists with EmployeeID: $($empidvalidation.EmployeeID)"
             $message = "Network ID Requried has been selected as NO. OnBoarding Process Terminated"
            New-UDInputAction -Content {
            New-UDCard -Title "OnBoarding Terminated" -Text $message
            
        }
        break

        
        $EmployeeIDCheck = $EmployeeID
        if($EmployeeIDCheck -ne $null)
        {
         $empidvalidation = Get-ADUser -Filter {employeeid -like $EmployeeID} -Properties displayname,employeeid | select displayname,employeeid
                        if($empidvalidation -ne $null)
                        {
                            $message = "User $($empidvalidation.displayname) already Exists with EmployeeID: $($empidvalidation.EmployeeID)"
                            New-UDInputAction -Content {
                            New-UDCard -Title "Error Message" -Text $message
            
                        }
        }
                        break

                
        }


        
        }

        if($UserType -eq "IM Associate")
        { 
           $name = $LastName + ", " + $FirstName
           
           
        }
        if($UserType -eq "Non IM Associate")
        {
   
           $name = $LastName + ", " + $FirstName + " (External)"
           
        }

        if($UserType -eq "Non IM Associate")
        {
           $man = Get-ADUser $ManagerNetworkId -Properties givenname,surname | select givenname,surname
           $title = $($man.givenname) + " " + $($man.surname) + "'s " + " " + "External"
           
        }
        
        if($UserType -eq "IM Associate")
        {
           $TitleAssc = $Title
          
        }

        

        $api = Invoke-RestMethod -Uri "http://localhost:8010/api/functions/onboard/$FirstName/$LastName/$Location"
        $result = $api.results
        #$($result.uid)
        [string]$Username = $($result.uid)
        #[string]$UPN = $($result.upn)


        $SQLServer = 'localhost'
            $SQLDBName = 'ADAutomation'
            $SqlQuery = "select * from dbo.TemplateMapping where UserType = '$UserType' AND Domain = '$Domain' AND Department = '$Department' AND Region = '$Region' AND Country = '$Country' AND Location = '$Location'"

            $SqlConnection = New-Object System.Data.SqlClient.SqlConnection
            $SqlConnection.ConnectionString = "Server = $SQLServer; Database = $SQLDBName; Integrated Security = True"

            $SqlCmd = New-Object System.Data.SqlClient.SqlCommand
            $SqlCmd.CommandText = $SqlQuery
            $SqlCmd.Connection = $SqlConnection

            $SqlAdapter = New-Object System.Data.SqlClient.SqlDataAdapter
            $SqlAdapter.SelectCommand = $SqlCmd

            $DataSet = New-Object System.Data.DataSet
            $SqlAdapter.Fill($DataSet)
 
            $SqlConnection.Close()

            #clear

            #write-host 'There is Template Found ' $DataSet.tables[0].rows.count ' AD Template:'

            foreach ($Row in $DataSet.Tables[0].Rows)
            {
  
              $templateid = [string]$Row.Item('TemplateID')
              $templateguid = [string]$Row.Item('TemplateObjectGUID')
              $path = [string]$Row.Item('MovePath')
  
              #write-host ($templateid + "   ObjectGUID  ===>  " + $templateguid + "  Move Path ===> " + $path)

  
              ####Use the specific AD Template from Query to Create Account####
              $u = Get-ADUser $templateguid -Properties samaccountname,city,streetAddress,physicalDeliveryOfficeName,POBox,postalCode,homepage,state,country,postalcode,department,company,description,profilePath,scriptPath,homeDirectory,homeDrive,homeDirectory
              $manageremail = Get-ADUser $ManagerNetworkId -Properties EmailAddress | select EmailAddress
              $date = (Get-Date).ToString('MM-dd-yyyy')

              $userinfo = "$($srtask) - Created On $date"
              #$password = Scramble-String $password
              $desc = $Department
              #$email = ($userlogonname + "@" + 'ingrammicro.com')

              if($UserType -eq "IM Associate")
              {
                                 

                ######
              $NewAdUserParameters = @{
            GivenName = [String]$FirstName
            Surname = [String]$LastName 
            Name = [String]$name
            DisplayName = [String]$name
            SamAccountName = [String]$Username
            AccountPassword = $securePassword
            Enable = $true
            EmployeeID = [String]$EmployeeID
            UserPrincipalName = [String]$UPN
            Path = [String]$path
            ChangePasswordAtLogon = $true
            Title = [String]$Title
            Manager = [String]$ManagerNetworkId
            Description = [String]$desc
            Department = [String]$Department
            
          }
            New-AdUser @NewAdUserParameters
            Set-ADUser $Username -Replace @{info=$notes}

          New-UDInputAction -Content {

             $checkusercreated = Get-ADUser -Filter {samaccountname -like $Username} -Properties * | select DisplayName,SamAccountName,EmployeeID,DistinguishedName    
             $message = New-UDHtml "<b>Username:</b> $($checkusercreated.SamAccountName) <br> <b>Password:</b> $password <br> <b>EmployeeId:</b> $($checkusercreated.EmployeeID) <br> <b>OU:</b> $($checkusercreated.DistinguishedName) <br> <b>Template Applied:</b> $($templateid)"
             New-UDCard -Title "User OnBoraded Sucessfully!!" -Content { $message }
        }
        }

        if($UserType -eq "Non IM Associate")
        {
              $NewAdUserParameters = @{
            GivenName = [String]$FirstName
            Surname = [String]$LastName 
            Name = [String]$name
            DisplayName = [String]$name
            SamAccountName = [String]$Username
            AccountPassword = $securePassword
            Enable = $true
            EmployeeID = $EmployeeID
            UserPrincipalName = [String]$UPN
            Path = [String]$path
            ChangePasswordAtLogon = $true
            Title = [String]$Title
            Manager = [String]$ManagerNetworkId
            Description = [String]$desc
            Department = [String]$Department
            
            }

            New-AdUser @NewAdUserParameters
            Set-ADUser $Username -Replace @{info=$notes}

            New-UDInputAction -Content {
             
             
             $checkusercreated = Get-ADUser -Filter {samaccountname -like $Username} -Properties * | select DisplayName,SamAccountName,EmployeeID,DistinguishedName    
             $message = New-UDHtml "<b>Username:</b> $($checkusercreated.SamAccountName) <br> <b>Password:</b> $password <br> <b>EmployeeId:</b> $($checkusercreated.EmployeeID) <br> <b>OU:</b> $($checkusercreated.DistinguishedName) <br> <b>Template Applied:</b> $($templateid)"
             New-UDCard -Title "User OnBoraded Sucessfully!!" -Content { $message }
             $messagecopy = @("Username: $($checkusercreated.SamAccountName)","Password: $password")
             New-UDButton -Floating -Icon clipboard -OnClick {
             Set-UDClipboard -Data "$($messagecopy)" -toastOnSuccess -toastOnError
             } 

            }
         }     

     
}
}
}


}

$ADGroupProv = New-UDPage -Name "ADGroupProvisioning" -Content {

New-UDCard -Title 'AD Group Provisioning' -Content {
New-UDInput -Title "Create New Security Group" -Endpoint {
        param(
            
            [Parameter(Mandatory)]
            [string]$GroupName,
            [Parameter(Mandatory)]
            [string]$GroupDescription,
            [Parameter(Mandatory)]
            [string]$GroupScope,
            [Parameter(Mandatory)]
            [string]$GroupOU
                        
        )

        $NewGroupParams = @{
        Name = [string]$GroupName
        Description = [string]$GroupDescription
        GroupScope = [string]$GroupScope
        Path = [string]$GroupOU
        }

        New-ADGroup @NewGroupParams
        New-UDInputAction -Content {
             
             
             $checkgroupcreated = Get-ADGroup -Filter {Name -like $GroupName} -Properties * | select Name,DistinguishedName    
             $message = New-UDHtml "<b>GroupName:</b> $($checkgroupcreated.Name) <br> <b>OU:</b> $($checkgroupcreated.DistinguishedName)"
             New-UDCard -Title "Group Created Sucessfully!!" -Content { $message }
                          
             } 
}
}
}


$Navigation = New-UDSideNav -None
$Init = New-UDEndpointInitialization -Function @("Invoke-Sqlcmd2")
$Dashboard = New-UDDashboard -Title "Active Directory Portal" -EndpointInitialization $Init -LoginPage $LoginPage -Pages @($hompage, $Page1, $Page2, $Page3, $OnBoarding, $ADGroupProv) -Navigation $Navigation -NavbarLinks @(
    New-UDLink -Text "Home" -Url "/Home"
    New-UDLink -Text "AD Users" -Url "/ADUsers"
    New-UDLink -Text "AD Groups" -Url "/ADGroups"
    New-UDLink -Text "AD OnBoarding" -Url "ADOnBoarding"
    New-UDLink -Text "AD Group Creation" -Url "ADGroupProvisioning"
    New-UDLink -Text "Reports" -Url "/Reports"
    
) 

Start-UDDashboard -Dashboard $Dashboard -AllowHttpForLogin -Port 10000