<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="/">
        <akomaNtoso>
            <act>
                <preface>
                    <docNumber><xsl:value-of select="normalize-space(CRS/TITLE_NUM/text())"/></docNumber>
                    <docTitle><xsl:value-of select="normalize-space(CRS/TITLE_TEXT/text())"/></docTitle>
                </preface>
                <body>
                    <title>
                        <num><xsl:value-of select="substring(normalize-space(CRS/TITLE_NUM/text()), string-length('TITLE')+2)"/></num>
                        <heading><xsl:value-of select="normalize-space(CRS/TITLE_TEXT/text())"/></heading>
                        <xsl:apply-templates select="CRS/ARTICLE_NUM"/>
                    </title>
                </body>
            </act>
        </akomaNtoso>
    </xsl:template>

    <xsl:template match="ARTICLE_NUM">
        <article>
            <num><xsl:value-of select="substring(normalize-space(text()), string-length('ARTICLE')+2)"/></num>
            <heading><xsl:value-of select="normalize-space(following-sibling::ARTICLE_TEXT[1])"/></heading>
            <xsl:apply-templates select="following-sibling::SECTION_TEXT[preceding-sibling::ARTICLE_NUM[1]=current()]"/>
        </article>
    </xsl:template>

    <xsl:template match="SECTION_TEXT">
        <xsl:variable name="heading" select="normalize-space(P/CATCH_LINE/RHFTO/following-sibling::M/following-sibling::text())"/>
        <xsl:variable name="isRemoved" select="' (Repealed)'=substring($heading, string-length($heading)-string-length(' (Repealed)')+1)"/>

        <section>
            <xsl:if test="$isRemoved">
                <xsl:attribute name="status">removed</xsl:attribute>
            </xsl:if>
            <num><xsl:value-of select="normalize-space(P/CATCH_LINE/RHFTO)"/></num>
            <heading>
                <xsl:choose>
                    <xsl:when test="$isRemoved">
                        <xsl:value-of select="substring($heading, 0, string-length($heading)-string-length(' (Repealed)'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="substring($heading, 0, string-length($heading))"/>
                    </xsl:otherwise>
                </xsl:choose>
            </heading>
            <xsl:apply-templates select="P"/>
        </section>
    </xsl:template>

    <xsl:template match="P">
        <xsl:variable name="text"><xsl:call-template name="paragraph-text"/></xsl:variable>

        <xsl:if test="string-length($text)">
            <paragraph>
                <num><xsl:value-of select="@N"/></num>
                <content><xsl:value-of select="$text"/></content>
            </paragraph>
        </xsl:if>
    </xsl:template>

    <xsl:template name="paragraph-text">
        <xsl:for-each select="text()[normalize-space(.)]">
            <xsl:if test="position() > 1">
                <xsl:if test="position() > 2"><xsl:text> </xsl:text></xsl:if>
                <xsl:value-of select="normalize-space(.)"/>
            </xsl:if>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>

