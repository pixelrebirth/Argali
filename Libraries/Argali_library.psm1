function Set-SSLCertificate {
	param ($IPPort)
	
	if ($(gci -Recurse Cert: | ? { $_.FriendlyName -eq "ArgaliCertificate" }).count -ne 1){
		gci -Recurse Cert: | ? { $_.FriendlyName -eq "ArgaliCertificate" } | remove-item
		$SSLSubject = "ArgaliCertificate"
		$SSLName = New-Object -com "X509Enrollment.CX500DistinguishedName.1"
		$SSLName.Encode("CN=$SSLSubject", 0)
		$SSLKey = New-Object -com "X509Enrollment.CX509PrivateKey.1"
		$SSLKey.ProviderName = "Microsoft RSA SChannel Cryptographic Provider"
		$SSLKey.KeySpec = 1
		$SSLKey.Length = 2048
		$SSLKey.SecurityDescriptor = "D:PAI(A;;0xd01f01ff;;;SY)(A;;0xd01f01ff;;;BA)(A;;0x80120089;;;NS)"
		$SSLKey.MachineContext = 1
		$SSLKey.ExportPolicy = 1
		$SSLKey.Create()
		$SSLObjectId = New-Object -com "X509Enrollment.CObjectIds.1"
		$SSLServerId = New-Object -com "X509Enrollment.CObjectId.1"
		$SSLServerId.InitializeFromValue("1.3.6.1.5.5.7.3.1")
		$SSLObjectId.add($SSLServerId)
		$SSLExtensions = New-Object -com "X509Enrollment.CX509ExtensionEnhancedKeyUsage.1"
		$SSLExtensions.InitializeEncode($SSLObjectId)
		$SSLCert = New-Object -com "X509Enrollment.CX509CertificateRequestCertificate.1"
		$SSLCert.InitializeFromPrivateKey(2, $SSLKey, "")
		$SSLCert.Subject = $SSLName
		$SSLCert.Issuer = $SSLCert.Subject
		$SSLCert.NotBefore = Get-Date
		$SSLCert.NotAfter = $SSLCert.NotBefore.AddDays(1825)
		$SSLCert.X509Extensions.Add($SSLExtensions)
		$SSLCert.Encode()
		$SSLEnrollment = New-Object -com "X509Enrollment.CX509Enrollment.1"
		$SSLEnrollment.InitializeFromRequest($SSLCert)
		$SSLEnrollment.CertificateFriendlyName = 'ArgaliCertificate'
		$SSLCertdata = $SSLEnrollment.CreateRequest(0)
		$SSLEnrollment.InstallResponse(2, $SSLCertdata, 0, "")
	}
	$Certificate = gci -Recurse Cert: | ? { $_.FriendlyName -eq "ArgaliCertificate" }
	$CertThumbprint = $Certificate[0].Thumbprint
	
	netsh http delete sslcert ipport="$IPPort" | Out-Null #this section should only run if it needs to be reinstalled  or port changes.
	netsh http add sslcert ipport="$IPPort" certhash="$CertThumbprint" appid="{00112233-4455-6677-8899-AABBCCDDEEFF}" | Out-Null
	"SSL Initialization Completed"
}

function Get-POST {

	param ($InputStream,$ContentEncoding)

	$PostStream = New-Object IO.StreamReader ($InputStream,$ContentEncoding)
	$PostStream = $PostStream.ReadToEnd()
	$PostStream = $PostStream.ToString()
	
	if ($PostStream)
	{
		$Literal_Post = $PostStream
		$PostStream = $PostStream.Replace("+"," ")
		$PostStream = $PostStream.Replace("%20"," ")
		$PostStream = $PostStream.Replace("%21","!")
		$PostStream = $PostStream.Replace('%22','"')
		$PostStream = $PostStream.Replace("%23","#")
		$PostStream = $PostStream.Replace("%24","$")
		$PostStream = $PostStream.Replace("%25","%")
		$PostStream = $PostStream.Replace("%26","&")
		$PostStream = $PostStream.Replace("%27","'")
		$PostStream = $PostStream.Replace("%28","(")
		$PostStream = $PostStream.Replace("%29",")")
		$PostStream = $PostStream.Replace("%2A","*")
		$PostStream = $PostStream.Replace("%2B","+")
		$PostStream = $PostStream.Replace("%2C",",")
		$PostStream = $PostStream.Replace("%2D","-")
		$PostStream = $PostStream.Replace("%2E",".")
		$PostStream = $PostStream.Replace("%2F","/")
		$PostStream = $PostStream.Replace("%3A",":")
		$PostStream = $PostStream.Replace("%3B",";")
		$PostStream = $PostStream.Replace("%3C","<")
		$PostStream = $PostStream.Replace("%3D","=")
		$PostStream = $PostStream.Replace("%3E",">")
		$PostStream = $PostStream.Replace("%3F","?")
		$PostStream = $PostStream.Replace("%5B","[")
		$PostStream = $PostStream.Replace("%5C","\")
		$PostStream = $PostStream.Replace("%5D","]")
		$PostStream = $PostStream.Replace("%5E","^")
		$PostStream = $PostStream.Replace("%5F","_")
		$PostStream = $PostStream.Replace("%7B","{")
		$PostStream = $PostStream.Replace("%7C","|")
		$PostStream = $PostStream.Replace("%7D","}")
		$PostStream = $PostStream.Replace("%7E","~")
		$PostStream = $PostStream.Replace("%7F","_")
		$PostStream = $PostStream.Replace("%7F%25","%")
		$PostStream = $PostStream.Split("&")

		$Object_Post = New-Object Psobject
		$Object_Post | Add-Member Noteproperty Literal_Post $Literal_Post
		foreach ($Post in $PostStream)
		{
			$Post = $Post.Split("=")
			$PostName = $Post[0]
			$PostValue = $Post[1]
			$Object_Post | Add-Member Noteproperty $PostName $PostValue
		}
		Write-Output $Object_Post
	}
			
}

function Set-Crypto {
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

function Validate-Session {
	param ($headers)
	$auth = $headers.authentication
	$auth.split(",")
	$username = $auth[0]
	$password = $auth[1]
	if ($(New-Object System.DirectoryServices.DirectoryEntry($("LDAP://" + ([ADSI] "" ).distinguishedName),$username,$password)).name -ne $null){
		
	}
}
