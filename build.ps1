# CAcert Root Certificates Installer
# Copyright (C) 2012  CAcert Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Requirements:
# Saxon-HE (for the wxl2xliff conversions,
#           any other XSLT 2.0 processor would do, but you probably would need
#           to adjust the wxl2xliff and xliff2wxl functions)

param (
	[string] $command  = "-help",
	[array]  $cultures = @{
"en-US"=""
"bg-BG"="bg"
"cs-CZ"="cs"
"da-DK"="da"
"de-DE"="de"
"el-GR"="el"
"es-ES"="es"
"fi-FI"="fi"
"fr-FR"="fr"
"hu-HU"="hu"
"it-IT"="it"
"ja-JP"="ja"
"lv-LV"="lv"
"nl-NL"="nl"
"pl-PL"="pl"
"pt-BR"="pt_BR"
"pt-PT"="pt_PT"
"ru-RU"="ru"
"sv-SE"="sv"
"tr-TR"="tr"
"zh-CN"="zh_CN"
"zh-TW"="zh_TW"
}.Keys
)

$base_name = "CAcert_Root_Certificates"
$culture_map = @{
"en-US"=""
"bg-BG"="bg"
"cs-CZ"="cs"
"da-DK"="da"
"de-DE"="de"
"el-GR"="el"
"es-ES"="es"
"fi-FI"="fi"
"fr-FR"="fr"
"hu-HU"="hu"
"it-IT"="it"
"ja-JP"="ja"
"lv-LV"="lv"
"nl-NL"="nl"
"pl-PL"="pl"
"pt-BR"="pt_BR"
"pt-PT"="pt"
"ru-RU"="ru"
"sv-SE"="sv"
"tr-TR"="tr"
"zh-CN"="zh_CN"
"zh-TW"="zh_TW"
}

$langid_map = @{
"en-US"=1033
"bg-BG"=1026
"cs-CZ"=1029
"da-DK"=1030
"de-DE"=1031
"el-GR"=1032
"es-ES"=1034
"fi-FI"=1035
"fr-FR"=1036
"hu-HU"=1038
"it-IT"=1040
"ja-JP"=1041
"lv-LV"=1062
"nl-NL"=1043
"pl-PL"=1045
"pt-BR"=1046
"pt-PT"=2070
"ru-RU"=1049
"sv-SE"=1053
"tr-TR"=1055
"zh-CN"=2052
"zh-TW"=1028
}

$wxs_file = ".\${base_name}.wxs"
$obj_dir = ".\build\objects\"
$obj_file = "${obj_dir}\${base_name}.wixobj"
$out_filename = "${base_name}.msi"


function wxl2xliff([String] $wxl, [String] $xliff = "${wxl}.xlf") {
	Transform.exe -xsl:wxl2xliff.xsl "-s:$wxl" "-o:$xliff"
	if ($LASTEXITCODE -ne 0) {
		throw "wxl2xliff: Conversion from `"$wxl`" to `"$xliff`" failed (error code: ${LASTEXITCODE})."
	}
}


function xliff2wxl([String] $xliff, [String] $wxl = "${xliff}.wxl") {
	Transform.exe -xsl:xliff2wxl.xsl "-s:$xliff" "-o:$wxl"
	if ($LASTEXITCODE -ne 0) {
		throw "xliff2wxl: Conversion from `"$xliff`" to `"$wxl`" failed (error code: ${LASTEXITCODE})."
	}
}


function l10n_template {
	Write-Output "Converting localisation template ..."
	wxl2xliff "${base_name}_template.wxl" "${base_name}_template.xlf"
	Write-Output "Localisation template converted.`n"
}


function update_l10n {
	Write-Output "Updating localisation files ..."
	$webclient = New-Object System.Net.WebClient
	
	foreach ($culture in $cultures) {
		if ($culture -eq "en-US") {
			continue
		}
		if ($culture_map.Keys -notcontains $culture) {
			Write-Warning "Skipping language $culture as there is no mapping to a simple language name defined"
			continue
		}
		
		Write-Output "Updating ${culture}:"
		
		$url = "http://translations.cacert.org/export/installer/"+$culture_map[$culture]+"/CAcert_Root_Certificates.xlf"
		$file_name = "${base_name}_${culture}.xlf"
		New-Item "$file_name" -ItemType file -Force|Out-Null
		
		Write-Output "Retrieving $url ..."
		$webclient.DownloadFile("$url", (Resolve-Path "$file_name").Path)
		if (!$?) {
			Write-Error "Could not retrieve $url => Skipping language ${culture}!"
			continue
		}
		Write-Output "Stored as ${file_name}."
		
		Write-Output "Converting ..."
		xliff2wxl "$file_name" "${base_name}_${culture}.wxl"
		Write-Output "Update of ${culture} complete."
	}
	
	Write-Output "Update of localisation files complete.`n"
}


$script:wix = $null
function get_wix_path {
	if ($script:wix) {
		# Fast path
		return $script:wix
	}
	
	$script:wix = $Env:WIX
	if ($script:wix) {
		return $script:wix
	}
	
	$reg_key = Get-ItemProperty "HKCU:\Software\Wow6432Node\Microsoft\Windows Installer XML\3.?" -ErrorAction SilentlyContinue
	$script:wix = $reg_key.InstallFolder
	if ($script:wix) {
		return $script:wix
	}
	
	$reg_key = Get-ItemProperty "HKLM:\Software\Wow6432Node\Microsoft\Windows Installer XML\3.?" -ErrorAction SilentlyContinue
	$script:wix = $reg_key.InstallFolder
	if ($script:wix) {
		return $script:wix
	}
	
	Write-Error "Could not find the WiX Toolset 3.X. Please make sure the WIX environment variable is set."
}

function build_objects {
	Write-Output "Compiling object file ..."
	
	$wix_bin = (get_wix_path)+"\bin\"
	
	New-Item "$obj_dir" -ItemType directory -Force | Out-Null
	
	&($wix_bin+"\candle.exe") -ext WixIIsExtension -out "$obj_file" "$wxs_file"
	if ($LASTEXITCODE -ne 0) {
		throw "Compiling the object file failed!"
	}
	
	Write-Output "Object file was compiled successfully.`n"
}

function build_installer([string] $culture="en-US") {
	Write-Output "Building installer for ${culture} ..."
	
	$wix_bin = (get_wix_path)+"\bin\"
	
	$culture_alias = $culture
	if ($culture -eq "en-US") {
		$culture_alias = "template"
	}
	
	$build_dir = ".\build\${culture_alias}\"
	New-Item "$build_dir" -ItemType directory -Force | Out-Null
	
	&($wix_bin+"\light.exe") -ext WixIIsExtension -ext WixUIExtension -cultures:${culture} -loc "${base_name}_${culture_alias}.wxl" -sice:ICE105 -out "${build_dir}\${out_filename}" "$obj_file"
	if ($LASTEXITCODE -ne 0) {
		throw "Building the installer for ${culture} failed!"
	}
	
	Write-Output "Installer for ${culture} successfully built."
}

function build_installers {
	Write-Output "Building installers for each specified culture ..."
	foreach ($culture in $cultures) {
		build_installer $culture
	}
	Write-Output "Succesfully built all specified installers.`n"
}

function build_transforms {
	Write-Output "Generating transform files for each specified culture ..."
	foreach ($culture in $cultures) {
		if ($culture -eq "en-US") {
			continue
		}
		
		Write-Output "Generating transform for langauge ${culture}"
		
		$wix_bin = (get_wix_path)+"\bin\"
		$build_dir = ".\build\${culture}\"
		New-Item "$build_dir" -ItemType directory -Force | Out-Null
		
		&($wix_bin+"\torch.exe") -p -t language -out "${build_dir}\${base_name}.mst" ".\build\template\${out_filename}" "${build_dir}\${out_filename}"
		if ($LASTEXITCODE -ne 0) {
			throw "Building the transform for ${culture} failed!"
		}
		
		Write-Output "Transform for ${culture} successfully built."
	}
	
	Write-Output "Successfully built all specified transforms.`n"
}

function msi_add_language_substorage([String] $msi, [String] $transform, [int] $langid) {
	Write-Output "Integrating transform for language ${langid} ..."
	
	# Import assembly
	$wix_path = get_wix_path
	Add-Type -Path "${wix_path}\SDK\Microsoft.Deployment.WindowsInstaller.dll"
	
	# Open MSI
	$db = new-object Microsoft.Deployment.WindowsInstaller.Database((Resolve-Path $msi).Path, [Microsoft.Deployment.WindowsInstaller.DatabaseOpenMode]::Transact)
	if (!$?) {
		throw "Could not open the MSI database"
	}
	try {
		# Set up the new record
		$record = $db.CreateRecord(2);                        if (!$?) { throw "Could not create record to be inserted as substorage!" }
		$record.SetString(1, "$langid");                          if (!$?) { throw "Could not set the name of the substorage to be inserted!" }
		$record.SetStream(2, (Resolve-Path $transform).Path); if (!$?) { throw "Could not read data from ${transform}!" }
		
		# Insert the new record
		$view = $db.OpenView("SELECT `Name`,`Data` FROM _Storages"); if (!$?) { throw "Could not open the substorages view!" }
		$view.Execute();                                             if (!$?) { throw "Could not execute the substorages view!" }
		$view.Assign($record);                                       if (!$?) { throw "Could not write the data to the substorage!" }
		$view.Close()
		
		$record.Close()
		
		# Update summary information stream
		$si = $db.SummaryInfo;    if (!$?) { throw "Could not get summary information!" }
		$template = $si.Template; if (!$?) { throw "Could not get the template property from the summary information!" }
		$template += ",${langid}"
		$si.Template = $template; if (!$?) { throw "Could not set the template property of the summary information!" }
		$si.Persist();            if (!$?) { throw "Could not save summary information!" }
		$si.Close()
		
		$db.Commit(); if (!$?) { throw "Could not commit outstanding database transactions!" }
	} finally {
		$db.Close()
	}
	
	Write-Output "Successfully integrated transform for language ${langid}."
}

function msi_add_language_transforms {
	Write-Output "Embedding the language transforms into the main installer ..."
	
	$result_path = ".\build\${out_filename}"
	Copy-Item ".\build\template\${out_filename}" $result_path
	
	foreach ($culture in $cultures) {
		if ($culture -eq "en-US") {
			continue
		}
		
		if ($langid_map.Keys -notcontains $culture) {
			Write-Warning "Skipping language $culture as there is no mapping to a language id defined"
			continue
		}
		
		$langid = $langid_map[$culture]
		$transform = ".\build\${culture}\${base_name}.mst"
		
		try {
			msi_add_language_substorage $result_path $transform $langid
		} catch {
			Write-Warning "Error when embedding the language transform for ${culture}:`n    ${_}`nSkipping ${culture}."
			continue
		}
	}
	
	Write-Output "Finished embedding the language transforms.`n"
}


##### Script Part #####

$help = "Build the CAcert Installer
build.ps1 [-command] <string> [[-cultures] <array>]
Available Commands:
l10n_template: generate localisation template (aka *_template.xlf)
update_l10n:   update the localisation files from the translation server
quick_build:   only build the english installer
installer:     build the complete installer

Usually you want to use 'update_l10n' first to download the localisation files
and then use 'installer' to build the final installer"

switch -regex ($command) {
	"(/\?|-*help)" {
		Write-Output $help
	}
	
	"l10n_template" {
		l10n_template
	}
	
	"update_l10n" {
		update_l10n
	}
	
	"quick_build" {
		build_objects
		build_installer
		
		Write-Output "Finished building the installer."
		Write-Output "You can find it in .\build\template\"
	}
	
	"installer" {
		build_objects
		build_installers
		build_transforms
		msi_add_language_transforms
		
		Write-Output "Finished building the installer."
	}
	
	default {
		Write-Output "Command $command not recognised"
		Write-Output $help
	}
}
