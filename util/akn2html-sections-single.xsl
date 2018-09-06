<?xml version="1.0"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
	xmlns:akn="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">

	<xsl:output method="html" version="5.0" doctype-system="about:legacy-compat"/>

	<xsl:template match="/">
		<html>
			<head>
				<title>Colorado Revised Statutes</title>
				<link rel="stylesheet" type="text/css" href="style.css"/>
			</head>
			<body>
				<xsl:for-each select="akn:akomaNtoso/akn:act/akn:body/*[self::akn:hcontainer|self::akn:title|self::akn:part|self::akn:subpart|self::akn:article]">
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
			<xsl:if test="akn:num">
				<xsl:value-of select="akn:num"/>
				<xsl:text> — </xsl:text>
			</xsl:if>
			<xsl:if test="akn:heading">
				<xsl:value-of select="akn:heading"/>
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
			<xsl:for-each select="akn:hcontainer|akn:title|akn:part|akn:subpart|akn:article|akn:section">
				<xsl:call-template name="hcontainer">
					<xsl:with-param name="indent" select="$indent+1"/>
				</xsl:call-template>
			</xsl:for-each>
		</xsl:if>
	</xsl:template>

</xsl:stylesheet>
