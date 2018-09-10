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
				<xsl:apply-templates select="akn:akomaNtoso/akn:act/akn:body/*"/>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="akn:hcontainer|akn:title|akn:part|akn:subpart|akn:article|akn:section">
        <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'" />
        <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'" />

		<div>
			<xsl:attribute name="class">
				<xsl:value-of select="local-name()"/>
				<xsl:if test="contains(@status, 'removed') or contains(@status, 'undefined')">
					<xsl:text> inactive</xsl:text>
				</xsl:if>
			</xsl:attribute>

			<xsl:if test="akn:num">
                <xsl:value-of select="translate(local-name(), $lowercase, $uppercase)"/>
                <xsl:text> </xsl:text>
				<xsl:value-of select="akn:num"/>
			</xsl:if>
			<xsl:if test="akn:num and akn:heading">
				<xsl:text> — </xsl:text>
			</xsl:if>
			<xsl:if test="akn:heading">
				<xsl:value-of select="akn:heading"/>
			</xsl:if>

			<xsl:if test="contains(@status, 'removed')">
				<xsl:text> [Repealed]</xsl:text>
			</xsl:if>
			<xsl:if test="contains(@status, 'undefined')">
				<xsl:text> [Reserved]</xsl:text>
			</xsl:if>
        </div>

		<xsl:apply-templates select="akn:hcontainer|akn:title|akn:part|akn:subpart|akn:article|akn:section"/>
	</xsl:template>

</xsl:stylesheet>
