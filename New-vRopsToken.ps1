# title: vRealize Operations Token Auth Get
# version: 1.0
# author: joshua warren
# date: 12 June 2020
# description: Will create and return an authentication token for vROPS.

function New-vRopsToken {
    [CmdletBinding()]param(
        [PSCredential]$credentialFile,
        [string]$vROPSServer
    )
    
    if ($vROPSServer -eq $null -or $vROPSServer -eq '') {
        $vROPSServer = ""
    }

    $vROPSUser = $credentialFile.UserName
    $vROPSPassword = $credentialFile.GetNetworkCredential().Password

    if ("TrustAllCertsPolicy" -as [type]) {} else {
    add-type @"
        using System.Net;
        using System.Security.Cryptography.X509Certificates;
        public class TrustAllCertsPolicy : ICertificatePolicy {
            public bool CheckValidationResult(
                ServicePoint srvPoint, X509Certificate certificate,
                WebRequest request, int certificateProblem) {
                return true;
            }
        }
"@ 
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
    }

    $BaseURL = "https://" + $vROPsServer + "/suite-api/api/"
    $BaseAuthURL = "https://" + $vROPsServer + "/suite-api/api/auth/token/acquire"
    $Type = "application/json"

    $AuthJSON =
    "{
      ""username"": ""$vROPSUser"",
      ""password"": ""$vROPsPassword""
    }"

    Try { $vROPSSessionResponse = Invoke-RestMethod -Method POST -Uri $BaseAuthURL -Body $AuthJSON -ContentType $Type }
    Catch {
        $_.Exception.ToString()
        $error[0] | Format-List -Force
    }

    $vROPSSessionHeader = @{"Authorization"="vRealizeOpsToken "+$vROPSSessionResponse.'auth-token'.token 
        "Accept"="application/json"}
    $vROPSSessionHeader.add("X-vRealizeOps-API-use-unsupported","true")
    return $vROPSSessionHeader
} 
