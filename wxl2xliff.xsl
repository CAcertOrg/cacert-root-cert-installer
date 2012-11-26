<?xml version="1.0"?>
<!--
wxl2xliff - convert WiX localization files to XLIFF using XSLT 2.0
Copyright (C) 2012  CAcert Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
-->

<xsl:transform version="2.0"
               xmlns="urn:oasis:names:tc:xliff:document:1.2"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:fn="http://www.w3.org/2005/xpath-functions"
               xmlns:wxl="http://schemas.microsoft.com/wix/2006/localization"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xsixsi:schemaLocation="http://www.w3.org/1999/XSL/Transform http://www.w3.org/2007/schema-for-xslt20.xsd
                                      urn:oasis:names:tc:xliff:document:1.2 http://docs.oasis-open.org/xliff/v1.2/cs02/xliff-core-1.2-strict.xsd">
	
	<xsl:strip-space elements="*"/>
	<xsl:preserve-space elements="wxl:String"/>
	<xsl:output method="xml" indent="yes" />
	
	<xsl:template match="/wxl:WixLocalization">
		<xliff version="1.2">
			<file original="{fn:replace(fn:base-uri(), '^.*/', '')}"
			      source-language="{@Culture}"
			      datatype="xml"
			      date="{fn:format-dateTime(fn:current-dateTime(),
			             '[Y0001]-[M01]-[D01]T[H01]:[m]:[s][Z]')}"
			      tool-id="wxl2xliff">
				
				<header>
					<phase-group>
						<phase phase-name="extraction"
						       process-name="extraction"
						       tool-id="wxl2xliff"
						       date="{fn:format-dateTime(fn:current-dateTime(),
						              '[Y0001]-[M01]-[D01]T[H01]:[m]:[s][Z]')}"/>
					</phase-group>
					
					<tool tool-id="wxl2xliff"
					      tool-name="wxl2xliff"
					      tool-version="0.1"
					      tool-company="CAcert Inc."/>
				</header>
				
				<body>
					<group id="language-information"
					       datatype="documentheader">
						<trans-unit id="culture-name">
							<source><xsl:value-of select="@Culture"/></source>
							<note from="wxl2xliff">A Microsoft Culture Name, a string identifying the locale used. Replace with one suitable for the language you are translating into. See http://msdn.microsoft.com/en-us/goglobal/bb896001.aspx for a list of Culture Names and corresponding codepages</note>
						</trans-unit>
						
						<trans-unit id="locale-id">
							<source><xsl:value-of select="@Language"/></source>
							<note from="wxl2xliff">A Microsoft Locale ID (LCID), an integer identifying the locale used. Replace with the one suitable for the language you are translating into. See http://msdn.microsoft.com/en-us/goglobal/bb964664.aspx for a list of LCIDs</note>
						</trans-unit>

						<trans-unit id="codepage">
							<source><xsl:value-of select="@Codepage"/></source>
							<note from="wxl2xliff">A Microsoft ANSI codepage, an integer identifying the character encoding to use to represent characters in the language used. Replace with the one suitable for the language you are translating into. See http://msdn.microsoft.com/en-us/goglobal/bb896001.aspx for a list of Culture Names and corresponding codepages</note>
						</trans-unit>
					</group>

					<xsl:apply-templates select="wxl:String"/>
				</body>
			</file>
		</xliff>
	</xsl:template>
	
	<xsl:template match="wxl:String">
		<trans-unit id="wxl_{@Id}" resname="{@Id}" restype="string">
			<source>
				<!-- Mark [variable] as place holders -->
				<xsl:analyze-string select="." regex="\[[^\[\]]+?\]">
					<xsl:matching-substring>
						<ph id="{position()}">
							<xsl:value-of select="."/>
						</ph>
					</xsl:matching-substring>
					<xsl:non-matching-substring>
						<xsl:value-of select="."/>
					</xsl:non-matching-substring>
					<xsl:fallback>
						<xsl:value-of select="."/>
					</xsl:fallback>
				</xsl:analyze-string>
			</source>
		</trans-unit>
	</xsl:template>
	
</xsl:transform>
