CAcert Root Certificate Installer
=================================

This installer is intended for the easier use of CAcert certificates on Windows systems. It imports the certificates into the proper certificate store which makes them usable in many applications that use the Windows certificate stores (e.g. Internet Explorer and Chrome). In the future it may also include code to import it into the Mozilla key stores.


Features
--------

- Per user and per machine installation possible
- Multi-language installer in a single file
- Supports silent install and other standard MSI features
- Signed installer (most usable for updates)



How to build
============

What you need
-------------

- Powershell (for the build script)
- WiX Toolkit (for building the MSI package)
- Saxon-HE (for building the localization files)
- Code signing certificate (for signed installers)
- Windows SDK (for signed installers)


Step by step
------------

There is a Powershell script to automate the build process, called `build.ps1`. You can use the argument `--help` to print a short usage information and available build targets. You can select the languages you want to be built by specifying an array of cultures after the command – e.g. `build.ps1 installer -cultures @("en-US","de-DE")`.

To build the installer you need to do the following:

- Download the current translations from the translation server:

		build.ps1 update_l10n

- Build the installer:

		build.ps1 installer

- Sign the installer (optional):

		build.ps1 signature



The parts
=========

Build script
------------

Powershell was chosen because it may already be installed on typical Windows systems, allows to directly use .Net objects used for downloading language files and special operations on MSI packages and integrates with Windows-specific things like registry keys and the like.


wxl2xliff
---------

The WiX toolkit comes with its own localization file format (`*.wxl`). In order to use our already existing translation infrastructure I wrote a transformation to the standard XLIFF format. XLIFF was chosen instead of PO files because they're also XML and allow to use XSLT for the transformation instead of probably complicated parsing of the PO format, and are more flexible in their use because they were specified exactly for the purpose of having a exchange format for localizations (e.g. they explicitly support translation of UI elements which WXL does too, although that is not supported in wxl2xliff yet).

The core of wxl2liff are the XSLT files `wxl2xliff.xsl` and `xliff2wxl.xsl` (for the reverse transformation). The XSLT files use some features from XSLT 2.0 so you need a XSLT 2.0 compliant processor.


WiX installer file
------------------

Named `CAcert_Root_certificates.wxs`. Describes the information that is necessary to build the MSI package. `<Product>` contains general meta information about the installed software. `<Package>` contains general meta information about the installer package itself. `<Feature>` is for the advanced installation where you can select which parts should be installed. The `<Directory>` contains files to be put into the file system while the `<ComponentGroup>` handles the installation into the certificate store. It does so by using the IIsExtension which comes with WiX. The installation status of the certificates in the trust store can't be detected directly so a registry key is set to indicate whether the component was installed (by specifying `KeyPath="yes"` on the accompanying `<RegistryValue>`). Whether to import the certificates into the per machine or per user certificate store is handled by the `<Condition>` check on the `ALLUSERS` variable. The `<WixVariable>` section specifies some custom content (logos and license) for the standard installation wizard that comes with WiX. Unfortunately the "Advanced" UI from WiX has a bug regarding supporting per machine and per user installations from the same package. Setting `ALLUSERS` to 2 should allow for detection whether the user may acquire administrative privileges and act accordingly, while specifying `MSIINSTALLPERUSER` to 1 selects the per user installation as the default (see the [MSDN Documentation](http://msdn.microsoft.com/en-us/library/windows/desktop/aa367559%28v=vs.85%29.aspx) for how this works exactly). However if an advanced installation is performed and per machine installation selected the installation path is still set to the default per user install path. The `<Publish Dialog="InstallScopeDlg">` entries work around that bug by explicitly setting the installation path after the selection of the instalation scope.


Multi-Language MSI packages
---------------------------

For each supported language a separate MSI package is built, then the differences between each localized installer and the main installer is calculated which gives a transform file (`*.mst`) which is basically a diff for the MSI database. Afterwards the transform for each localization is embedded into the base installer by adding it as a substorage with the language id set as key and the summary information stream is updated to tell MSI that the language is supported by the installer.


Signature
---------

The signtool (contained in the Windows SDK) is used to sign the installer. It looks for a certificate with the subject "CAcert Release Signing" in the certificate store to sign the installer (feel free to adjust) and uses the Verisign timestamping service to make the signature valid beyond the expiration date of the used certificate.
