<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0"
	xpath-default-namespace="http://docs.oasis-open.org/legaldocml/ns/akn/3.0/CSD14">

	<xsl:output method="xml" omit-xml-declaration="yes" encoding="UTF-8"/>

	<xsl:template match="/akomaNtoso/act/body">
		<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
		<html>
			<head>
				<title>Colorado Revised Statutes</title>
				<link rel="stylesheet" type="text/css" href="style.css"/>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
			</head>
			<body>
				<xsl:for-each select="hcontainer|title|part|subpart|article">
					<xsl:call-template name="hcontainer">
						<xsl:with-param name="indent" select="0"/>
					</xsl:call-template>
				</xsl:for-each>
			</body>
		</html>
	</xsl:template>

	<!-- XXX need template for each type of Akoma Ntoso document? -->

	<xsl:template name="hcontainer">
		<xsl:param name="indent"/>
		<div>
			<xsl:attribute name="class">
				<xsl:choose>
					<xsl:when test="contains(@status, 'repealed') or contains(@status, 'reserved')">
						<xsl:value-of select="concat('indent-',$indent,' inactive')"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="concat('indent-',$indent)"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:if test="@name">
				<xsl:value-of select="@name"/>
			</xsl:if>
			<xsl:if test="heading[text()]">
				<xsl:text>: </xsl:text>
				<xsl:value-of select="heading[text()]"/>
			</xsl:if>
			<!--<xsl:if test="contains(@status, 'repealed')">
				<xsl:text> [Repealed]</xsl:text>
			</xsl:if>
			<xsl:if test="contains(@status, 'reserved')">
				<xsl:text> [Reserved]</xsl:text>
			</xsl:if>-->
			<xsl:choose>
				<xsl:when test="contains(@status, 'repealed')">
					<xsl:text> [Repealed]</xsl:text>
				</xsl:when>
				<xsl:when test="contains(@status, 'reserved')">
					<xsl:text> [Reserved]</xsl:text>
				</xsl:when>
			</xsl:choose>
		</div>
		<br/>
		<xsl:if test="not(contains(@status, 'repealed')) and not(contains(@status, 'reserved'))">
			<xsl:for-each select="hcontainer|title|part|subpart|article">
				<xsl:call-template name="hcontainer">
					<xsl:with-param name="indent" select="$indent+1"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
