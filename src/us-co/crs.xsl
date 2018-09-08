<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://docs.oasis-open.org/legaldocml/ns/akn/3.0">
    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="/">
        <akomaNtoso>
            <act>
                <preface>
                    <xsl:apply-templates select="CRS/TITLE_NUM"/>
                    <xsl:apply-templates select="CRS/TITLE_TEXT"/>
                </preface>
                <body>
                    <xsl:apply-templates select="CRS/ARTICLE_NUM"/>
                </body>
            </act>
        </akomaNtoso>
    </xsl:template>

    <xsl:template match="TITLE_NUM">
        <docNumber><xsl:value-of select="normalize-space(text())"/></docNumber>
    </xsl:template>

    <xsl:template match="TITLE_TEXT">
        <docTitle><xsl:value-of select="normalize-space(text())"/></docTitle>
    </xsl:template>

    <xsl:template match="ARTICLE_NUM">
        <article>
            <num><xsl:value-of select="normalize-space(text())"/></num>
            <heading><xsl:value-of select="normalize-space(following-sibling::ARTICLE_TEXT[1])"/></heading>
            <xsl:apply-templates select="following-sibling::SECTION_TEXT[preceding-sibling::ARTICLE_NUM[1]=current()]"/>
        </article>
    </xsl:template>

    <xsl:template match="SECTION_TEXT">
        <section>
            <num><xsl:value-of select="normalize-space(P/CATCH_LINE/RHFTO)"/></num>
            <heading><xsl:value-of select="normalize-space(P/CATCH_LINE/RHFTO/following-sibling::M/following-sibling::text())"/></heading>
            <xsl:apply-templates select="P"/>
        </section>
    </xsl:template>

    <xsl:template match="P">
        <paragraph>
            <num><xsl:value-of select="@N"/></num>
            <content><xsl:call-template name="paragraph-text"/></content>
        </paragraph>
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

